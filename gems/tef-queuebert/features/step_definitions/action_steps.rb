require 'tef/development/step_definitions/action_steps'


When(/^"([^"]*)" is searched for tests$/) do |target|
  @output ||= {}
  filters = {}

  filters[:excluded_tags] = @excluded_tag_filters if @excluded_tag_filters
  filters[:included_tags] = @included_tag_filters if @included_tag_filters
  filters[:excluded_paths] = @excluded_path_filters if @excluded_path_filters
  filters[:included_paths] = @included_path_filters if @included_path_filters

  @output[target] = TEF::Queuebert::Searching.find_test_cases(@default_file_directory, target, filters)
end

When(/^"([^"]*)" is searched for tests using the following tag filters:$/) do |target, filters|
  @output ||= {}
  options = {}

  filters.hashes.each do |filter|
    case filter['filter type']
      when 'excluded'
        options[:excluded_tags] = [filter['filter'].split('|').collect { |filter| process_filter(filter) }]
      when 'included'
        options[:included_tags] = [filter['filter'].split('|').collect { |filter| process_filter(filter) }]
      else
        raise("Unknown filter type #{filter['filter type']}")
    end
  end

  @output[target] = TEF::Queuebert::Searching.find_test_cases(@default_file_directory, target, options)
end

When(/^"([^"]*)" is searched for tests using the following path filters:$/) do |target, filters|
  @output ||= {}
  excluded_filters = []
  included_filters = []

  filters.hashes.each do |filter|
    case filter['filter type']
      when 'excluded'
        excluded_filters << process_filter(filter['filter'])
      when 'included'
        included_filters << process_filter(filter['filter'])
      else
        raise("Unknown filter type #{filter['filter type']}")
    end
  end

  @output[target] = TEF::Queuebert::Searching.find_test_cases(@default_file_directory, target, excluded_paths: excluded_filters, included_paths: included_filters)
end

When(/^test cases are extracted from "([^"]*)" using "([^"]*)"$/) do |target, included_tag_filters|
  @output ||= {}
  options = {}

  options[:included_tags] = eval("[#{included_tag_filters}]")

  @output[target] = TEF::Queuebert::Searching.find_test_cases(@default_file_directory, target, options)
end

When(/^a request for a test suite is received$/) do
  @explicit_test_cases = ["test.feature:1", "test.feature:2"]
  @root_location = 'root_dir'

  request = @base_request.dup
  request['tests'] = @explicit_test_cases
  request['root_location'] = @root_location
  request['suite_guid'] = '112233'

  request_queue_name = "tef.#{@tef_env}.queuebert.request"

  @request = request.to_json
  get_queue(request_queue_name).publish(@request)
end

When(/^a request for the test suite is received$/) do
  TEF::Queuebert::Queuer.new(in_queue: @fake_publisher, output_exchange: @out_message_exchange)

  request = @base_request.dup
  request['directories'] = @explicit_directories if @explicit_directories
  request['tests'] = @explicit_test_cases if @explicit_test_cases
  request['test_directory'] = @test_directory if @test_directory
  request['root_location'] = @root_location if @root_location

  @fake_publisher.call(create_mock_delivery_info, @mock_properties, request.to_json)
end

When(/^a test suite is created for the request$/) do
  TEF::Queuebert::Queuer.new(in_queue: @fake_publisher, output_exchange: @out_message_exchange)

  @fake_publisher.call(create_mock_delivery_info, @mock_properties, @request)
end

When(/^the following suite request is received:$/) do |request|
  TEF::Queuebert::Queuer.new(in_queue: @fake_publisher, output_exchange: @out_message_exchange)

  request = process_path(request)
  @fake_publisher.call(create_mock_delivery_info, @mock_properties, request)
end

When(/^a suite request is rejected$/) do
  TEF::Queuebert::Queuer.new(in_queue: @fake_publisher, output_exchange: @out_message_exchange)

  @fake_publisher.call(create_mock_delivery_info, @mock_properties, '{"bad":"request"}')
end

When(/^Queubert is started$/) do
  options = {}
  options[:name_prefix] = @prefix if @prefix
  options[:in_queue] = @request_queue_name if @request_queue_name
  options[:output_exchange] = @output_exchange_name if @output_exchange_name

  @queuebert = TEF::Queuebert::Queuebert.new(options)
  @queuebert.start
end

When(/^a task is created for it$/) do
  @request = JSON.parse(@request, symbolize_names: true)

  @created_tasks = TEF::Queuebert::Tasking.create_tasks_for(@request, @request[:tests])
end

When(/^the following request for a test suite is sent to it:$/) do |json_request|
  @request = process_path(json_request)
  request_queue_name = "tef.#{@tef_env}.queuebert.request"

  get_queue(request_queue_name).publish(@request)
end

And(/^messages have been sent out in response$/) do
  out_message_exchange = "tef.#{@tef_env}.queuebert_generated_messages"
  message_queue = @bunny_channel.queue('test_message_capture_queue')
  message_queue.bind(out_message_exchange, routing_key: '#')

  # Give the messages a moment to get there
  wait_for { message_queue.message_count }.not_to eq(0)

  @received_messages = messages_from_queue('test_message_capture_queue')
end
