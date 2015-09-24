require 'tef/development/step_definitions/setup_steps'


Given(/^the following feature file "([^"]*)":$/) do |file_name, file_text|
  @current_directory ||= @default_file_directory

  File.open("#{@current_directory}/#{file_name}", 'w') { |file| file.write(file_text) }
end

Given(/^the directory "([^"]*)"$/) do |directory_name|
  @current_directory = directory_name.include?('path/to') ? process_path(directory_name) : "#{@default_file_directory}/#{directory_name}"

  FileUtils.mkpath(@current_directory)
end

Given(/^the following tag filters:$/) do |filters|
  filters.hashes.each do |filter|
    case filter['filter type']
      when 'excluded'
        @excluded_tag_filters = filter['filter']
      when 'included'
        @included_tag_filters = filter['filter']
      else
        raise("Unknown filter type #{filter['filter type']}")
    end
  end
end

And(/^the following path filters:$/) do |filters|
  @excluded_path_filters = []
  @included_path_filters = []

  filters.hashes.each do |filter|
    case filter['filter type']
      when 'excluded'
        @excluded_path_filters << process_filter(filter['filter'])
      when 'included'
        @included_path_filters << process_filter(filter['filter'])
      else
        raise("Unknown filter type #{filter['filter type']}")
    end
  end
end

Given(/^a created task$/) do
  @test_task = TEF::Queuebert::Tasking.create_tasks_for({name: "Request Foo",
                                                          owner: "Owner Bar",
                                                          dependencies: "foo|bar", }, ['path/to/some.feature:1']).first
end

Given(/^a queue to receive from$/) do
  @mock_properties = create_mock_properties
  @mock_exchange = create_mock_exchange
  @mock_channel = create_mock_channel(@mock_exchange)
  @mock_in_queue = create_mock_queue(@mock_channel)

  @fake_publisher = create_fake_publisher(@mock_channel)
end

Given(/^queues to publish to$/) do
  @mock_manager_queue = create_mock_queue
  @mock_keeper_queue = create_mock_queue
end

Given(/^Queuebert is running$/) do
  @queuebert = TEF::Queuebert::Queuebert.new
  @queuebert.start
end

Given(/^the following tests need tasks created for them:$/) do |test_cases|
  @explicit_test_cases = test_cases.raw.flatten
  @explicit_test_cases.map! { |test_case| process_path(test_case) }
end

Given(/^no tests need tasks created for them$/) do
  @explicit_test_cases = nil
end

When(/^the following directories need tasks created for them:$/) do |directories|
  @explicit_directories = directories.raw.flatten
  @explicit_directories.map! { |directory| process_path(directory) }
end

When(/^no directories need tasks created for them$/) do
  @explicit_directories = nil
end

Given(/^a test directory of "([^"]*)"$/) do |path|
  @test_directory = process_path(path)
end

Given(/^message in\/out queues for Queuebert have not been yet been created$/) do
  request_queue_name = "tef.#{@tef_env}.queuebert.request"
  task_queue_name = "tef.#{@tef_env}.task_queue.control"

  get_queue(request_queue_name).delete if @bunny_connection.queue_exists?(request_queue_name)
  get_queue(task_queue_name).delete if @bunny_connection.queue_exists?(task_queue_name)
end

And(/^a request queue name of "([^"]*)"$/) do |queue_name|
  @request_queue_name = queue_name
end

And(/^a task queue name of "([^"]*)"$/) do |queue_name|
  @task_queue_name = queue_name
end

And(/^messages queues are available$/) do
  @request_queue_name = "tef.#{@tef_env}.queuebert.request"
  @task_queue_name = "tef.#{@tef_env}.task_queue.control"
  @keeper_queue_name = "tef.#{@tef_env}.keeper.cucumber"

  @expected_queues = [@request_queue_name, @task_queue_name, @keeper_queue_name]

  @expected_queues.each do |queue_name|
    raise("Message queue #{queue_name} has not been created yet.") unless @bunny_connection.queue_exists?(queue_name)
  end
end

And(/^a location "([^"]*)"$/) do |directory_path|
  @current_directory = "#{@default_file_directory}/#{directory_path}"
  @base_location = @current_directory

  FileUtils.mkdir(@current_directory)
end

And(/^all of that stuff is in "([^"]*)" as well$/) do |directory_path|
  source_location = @base_location
  target_location = "#{@default_file_directory}/#{directory_path}"
  FileUtils.mkdir(target_location)

  entries = Dir.entries(source_location)
  entries.delete('.')
  entries.delete('..')

  entries.each do |entry|
    FileUtils.copy_entry("#{source_location}/#{entry}", "#{target_location}/copy_of_#{entry}")
  end
end

And(/^a root location of "([^"]*)"$/) do |directory_path|
  @root_location = "#{@default_file_directory}/#{directory_path}"
end

Given(/^the following suite request:$/) do |request|
  if request.include?('<lots of tests>')
    many = 1000

    tests = ''
    many.times { |count| tests << "\"foo.feature:#{count+1}\"," }
    tests.chop!

    request.sub!('<lots of tests>', tests)
  end

  @request = request
end
