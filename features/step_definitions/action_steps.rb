When(/^a request for a test suite is sent$/) do
  # Queuebert needs to be ready
  request_queue_name = "tef.#{@tef_env}.queuebert.request"
  wait_for { @bunny_connection.queue_exists?(request_queue_name) }.to be true


  @explicit_test_cases = ["more_features/test_feature_2.feature:3"]
  @test_suite_guid = 112233

  request = @base_request.dup
  request['tests'] = @explicit_test_cases
  request['root_location'] = @test_search_root
  request['working_directory'] = 'fake_cucumber_suite'
  request['test_directory'] = 'fake_cucumber_suite/features'
  request['directories'] = ['.']
  request['command_line_options'] = {options: ['-r features']}
  request['suite_guid'] = @test_suite_guid
  request['owner'] = 'owner_foo'
  request['env'] = 'env_foo'
  request['name'] = 'TEF test suite'

  get_queue(request_queue_name).publish(request.to_json)
end
