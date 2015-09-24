require 'tef/development/step_definitions/verification_steps'


Then(/^the following test cases are discovered for "([^"]*)":$/) do |target, expected_test_cases|
  expected_test_cases = expected_test_cases.raw.flatten
  expected_test_cases.map! { |test_case| process_path(test_case) }

  expect(@output[target]).to match_array(expected_test_cases)
end

Then(/^no test cases are discovered for "([^"]*)"$/) do |target|
  expect(@output[target]).to be_empty
end

Then(/^The following filter types are possible:$/) do |filter_types|
  filter_types = filter_types.raw.flatten.map { |filter| filter.to_sym }

  expect(TEF::Queuebert::Searching.known_filters).to match_array(filter_types)
end

Then(/^"([^"]*)" are found for "([^"]*)"$/) do |test_cases, target|
  expected_test_cases = test_cases.delete(' ').split(',')
  expected_test_cases.map! { |test_case| test_case.sub('path/to', @default_file_directory) }

  expect(@output[target]).to match_array(expected_test_cases)
end

Then(/^"([^"]*)" are found$/) do |test_cases|
  expected_test_cases = test_cases.delete(' ').split(',')
  expected_test_cases.collect! { |test_case| test_case.sub('path/to', @default_file_directory) }

  found_test_cases = @output.values.flatten

  expect(found_test_cases).to match_array(expected_test_cases)
end

Then(/^tasks have been created for the following tests:$/) do |test_cases|
  expected_test_cases = test_cases.raw.flatten
  expected_test_cases.map! { |test_case| process_path(test_case) }
  received_test_tasks = []

  expect(@mock_manager_queue).to have_received(:publish).at_least(:once) do |arg|
    received_test_tasks << JSON.parse(arg, symbolize_names: true)
  end

  received_test_tasks.map! { |task| task[:task_data][:cucumber_options][:file_paths] }.flatten!

  expect(received_test_tasks).to match_array(expected_test_cases)
end

Then(/^the following tests have only a single task created for them:$/) do |test_cases|
  expected_test_cases = test_cases.raw.flatten
  expected_test_cases.map! { |test_case| process_path(test_case) }
  received_test_tasks = []

  expect(@mock_manager_queue).to have_received(:publish).at_least(:once) do |arg|
    received_test_tasks << JSON.parse(arg, symbolize_names: true)
  end

  received_test_tasks.map! { |task| task[:task_data][:cucumber_options][:file_paths] }.flatten!

  expected_test_cases.each do |test_case|
    expect(received_test_tasks.count { |test_task| test_task == test_case }).to eq(1)
  end
end

Then(/^the task contains, at least, the following pieces:$/) do |needed_data|
  required_data = needed_data.hashes

  required_data.each do |data_piece|
    required_key = data_piece['required_key'].to_sym
    expected_value = data_piece['expected_value']

    expect(@test_task).to have_key(required_key)

    if expected_value == '<non-null>'
      expect(@test_task[required_key]).to_not be_nil
    else
      if expected_value.start_with?('/')
        expected_value = expected_value.slice(1..-2)
        expected_value = Regexp.new(expected_value)
      else
        expected_value = Regexp.new("^#{Regexp.escape(expected_value)}$")
      end

      expect(@test_task[required_key]).to match(expected_value)
    end
  end
end

Then(/^the task contains the test case that needs to be executed$/) do
  expect(@test_task[:task_data][:cucumber_options][:file_paths].first).to match(/^.+:\d+$/)
end

Then(/^the request is accepted$/) do
  expect(@mock_exchange).to have_received(:publish).with(/Request received/, hash_including(:routing_key => @mock_properties.reply_to, :correlation_id => @mock_properties.correlation_id))
end

Then(/^the request is rejected$/) do
  expect(@mock_exchange).to have_received(:publish).with(/Invalid request/, hash_including(:routing_key => @mock_properties.reply_to, :correlation_id => @mock_properties.correlation_id))
end

Then(/^rejection response includes the correct request format:$/) do |expected_content|
  expect(@mock_exchange).to have_received(:publish).with(Regexp.new(Regexp.escape(expected_content.delete(" \n"))), hash_including(:routing_key => @mock_properties.reply_to, :correlation_id => @mock_properties.correlation_id))
end

Then(/a suite is created and sent to the manager$/) do
  task_queue_name = "tef.#{@tef_env}.task_queue.control"
  queue = get_queue(task_queue_name)

  # Give the tasks a moment to get there
  wait_for { queue.message_count }.not_to eq(0)

  received_test_tasks = []
  queue.message_count.times do
    received_test_tasks << queue.pop
  end

  received_test_tasks.map! { |task| JSON.parse(task[2], symbolize_names: true)[:task_data][:cucumber_options][:file_paths] }.flatten!

  expect(received_test_tasks).to match_array(@explicit_test_cases)
end

Then(/a suite notification is sent to the keeper$/) do
  keeper_queue_name = "tef.#{@tef_env}.keeper.cucumber"
  queue = get_queue(keeper_queue_name)

  # Give the suite a moment to get there
  wait_for { queue.message_count }.not_to eq(0)

  received_suite_notifications = []
  queue.message_count.times do
    received_suite_notifications << queue.pop
  end

  received_suite_notifications.map! { |notification| JSON.parse(notification[2], symbolize_names: true) }.flatten!
  creation_notifications = received_suite_notifications.select { |notification| notification[:type] == 'suite_creation' }
  original_request = JSON.parse(@request, symbolize_names: true)

  expect(creation_notifications.first[:suite_guid]).to eq(original_request[:suite_guid])
end

Then(/the suite notification is sent to the keeper$/) do
  received_suite_notifications = []
  expect(@mock_keeper_queue).to have_received(:publish).at_least(:once) do |message|
    received_suite_notifications << JSON.parse(message, symbolize_names: true)
  end


  creation_notifications = received_suite_notifications.select { |notification| notification[:type] == 'suite_creation' }
  original_request = JSON.parse(@request, symbolize_names: true)

  expect(creation_notifications.first[:suite_guid]).to eq(original_request[:suite_guid])
end

Then(/no suite is created or sent to the manager$/) do
  expect(@mock_manager_queue).to_not have_received(:publish)
end

Then(/^the following notification is sent to the keeper$/) do |text|
  expect(@mock_keeper_queue).to have_received(:publish).at_least(:once) do |message|
    actual_message = JSON.parse(message, symbolize_names: true)

    text.sub!('<now>', "#{DateTime.now}")
    expected_message = JSON.parse(text, symbolize_names: true)

    # No way to know the ids ahead of time so just a simple count of them
    expect(actual_message[:task_ids].count).to eq(expected_message[:task_ids].count)

    expected_message.delete(:task_ids)
    actual_message.delete(:task_ids)

    # Now-ish
    now = DateTime.now
    creation_time = DateTime.parse(actual_message[:requested_time])
    expect((now - creation_time)*60*60*24).to be <= 1

    expected_message.delete(:requested_time)
    actual_message.delete(:requested_time)

    expect(actual_message).to eq(expected_message)
  end
end

Then(/^at least one suite update notification is sent to the keeper:$/) do |text|
  received_suite_notifications = []
  expect(@mock_keeper_queue).to have_received(:publish).at_least(:once) do |message|
    received_suite_notifications << JSON.parse(message, symbolize_names: true)
  end

  update_notifications = received_suite_notifications.select { |notification| notification[:type] == 'suite_update' }

  original_request = JSON.parse(@request, symbolize_names: true)
  text.sub!('<total_test_count>', "#{original_request[:tests].count}")
  text.sub!('<some_number_of_task_ids>', "99999")

  expected_message = JSON.parse(text, symbolize_names: true)
  actual_message = update_notifications.first

  # No way to know the ids ahead of time so just make sure that some are there
  expect(actual_message[:task_ids].count).to be > 0

  expected_message.delete(:task_ids)
  actual_message.delete(:task_ids)

  expect(actual_message).to eq(expected_message)
end

Then(/^the received notifications cumulatively contain all of the task ids for the test suite$/) do
  received_suite_notifications = []
  expect(@mock_keeper_queue).to have_received(:publish).at_least(:once) do |message|
    received_suite_notifications << JSON.parse(message, symbolize_names: true)
  end

  original_request = JSON.parse(@request, symbolize_names: true)

  # No way to know the ids ahead of time so just a simple count of them
  expected_id_count = original_request[:tests].count
  # received_id_count = update_notifications.reduce(0) { |sum, notification| sum + notification[:task_ids].count }
  received_id_count = received_suite_notifications.reduce(0) { |sum, notification| sum + notification[:task_ids].count }

  expect(received_id_count).to eq(expected_id_count)
end

Then(/^message in\/out queues for Queuebert have been created$/) do
  request_queue_name = "tef.#{@tef_env}.queuebert.request"
  task_queue_name = "tef.#{@tef_env}.task_queue.control"

  expect(@bunny_connection.queue_exists?(request_queue_name)).to be true
  expect(@bunny_connection.queue_exists?(task_queue_name)).to be true
end

And(/^Queuebert can still receive and send messages through them$/) do
  task_queue = get_queue(@task_queue_name)
  request_queue = get_queue(@request_queue_name)

  request_queue.publish('{"name": "foo", "dependencies": "foo|bar", "tests": ["a test"], "root_location": "foo"}')

  # Give the tasks a moment to get there
  wait_for { task_queue.message_count }.not_to eq(0)

  received_test_tasks = []
  task_queue.message_count.times do
    received_test_tasks << task_queue.pop
  end

  received_test_tasks.map! { |task| JSON.parse(task[2], symbolize_names: true)[:task_data][:cucumber_options][:file_paths] }.flatten!

  expect(received_test_tasks).to match_array(["a test"])
end

Then(/^the created task matches the following:$/) do |task|
  task = JSON.parse(task, symbolize_names: true)
  task[:guid] = @created_tasks.first[:guid]

  expect(task[:guid]).to_not be_nil
  expect(@created_tasks.first).to eq(task)
end

Then(/^the following task message was sent to the manager:$/) do |task_json|
  # Masking out data that we can't know ahead of time
  @received_task_messages.each { |task| task['guid'] = '<some guid>' }

  task_json = process_path(task_json) if task_json.include?('path/to')

  expect(@received_task_messages).to include(JSON.parse(task_json.to_s))
  @received_task_messages.delete(JSON.parse(task_json.to_s))
end

And(/^the following suite notification message was sent to the keeper:$/) do |notification_json|
  # Only one notification should get sent
  expect(@received_suite_notifications_messages.count).to eq(1)

  actual_notification = @received_suite_notifications_messages.shift
  expected_notification = JSON.parse(notification_json.to_s)

  # Masking out data that we can't know ahead of time but making sure that it is at least there
  expect(actual_notification).to have_key('task_ids')
  actual_notification.delete('task_ids')
  expected_notification.delete('task_ids')

  expect(actual_notification).to have_key('requested_time')
  actual_notification.delete('requested_time')
  expected_notification.delete('requested_time')

  # Everything else should match
  expect(actual_notification).to eq(expected_notification)
end

And(/^no other messages were sent$/) do
  expect(@received_task_messages).to be_empty
  expect(@received_suite_notifications_messages).to be_empty
end
