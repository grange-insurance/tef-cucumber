And(/^The following attributes are tracked for a scenario$/) do |attributes|
  expected_column_names_array = attributes.raw.flatten

  found_column_names_array = TEF::CukeKeeper::Models::Scenario.column_names
  found_column_names_array.delete('id') # We don't care about the database's internal id column

  expect(found_column_names_array).to match_array expected_column_names_array
end

And(/^The following attributes are tracked for a suite$/) do |attributes|
  expected_column_names_array = attributes.raw.flatten

  found_column_names_array = TEF::CukeKeeper::Models::TestSuite.column_names
  found_column_names_array.delete('id') # We don't care about the database's internal id column

  expect(found_column_names_array).to match_array expected_column_names_array
end

And(/^The following attributes are tracked for a feature$/) do |attributes|
  expected_column_names_array = attributes.raw.flatten

  found_column_names_array = TEF::CukeKeeper::Models::Feature.column_names
  found_column_names_array.delete('id') # We don't care about the database's internal id column

  expect(found_column_names_array).to match_array expected_column_names_array
end

Given(/^a test result with data$/) do
  std_out = "Test 2 is happening\nBundler mode: dev\nJSON_EXPANDED_FORMATTER_CONSUMABLE_OUTPUT_STARTS_HERE[\n  {\n    \"keyword\": \"Feature\",\n    \"name\": \"Test feature 2\",\n    \"line\": 1,\n    \"description\": \"\",\n    \"id\": \"test-feature-2\",\n    \"uri\": \"features/more_features/test_feature_2.feature\",\n    \"elements\": [\n      {\n        \"keyword\": \"Scenario\",\n        \"name\": \"Test 2\",\n        \"line\": 3,\n        \"description\": \"\",\n        \"id\": \"test-feature-2;test-2\",\n        \"type\": \"scenario\",\n        \"steps\": [\n          {\n            \"keyword\": \"* \",\n            \"name\": \"echo \\\"Test 2 is happening\\\"\",\n            \"line\": 4,\n            \"match\": {\n              \"arguments\": [\n                {\n                  \"offset\": 6,\n                  \"val\": \"Test 2 is happening\"\n                }\n              ],\n              \"location\": \"features/step_definitions/test_step_defs.rb:1\"\n            },\n            \"result\": {\n              \"status\": \"passed\",\n              \"duration\": 123000000\n            }\n          },\n          {\n            \"keyword\": \"* \",\n            \"name\": \"explode\",\n            \"line\": 5,\n            \"match\": {\n              \"location\": \"features/step_definitions/test_step_defs.rb:5\"\n            },\n            \"result\": {\n              \"status\": \"failed\",\n              \"error_message\": \"Boom!!! (RuntimeError)\\n./features/step_definitions/test_step_defs.rb:6:in `/^explode$/'\\nfeatures/more_features/test_feature_2.feature:5:in `* explode'\",\n              \"duration\": 0\n            }\n          }\n        ]\n      }\n    ]\n  }\n]JSON_EXPANDED_FORMATTER_CONSUMABLE_OUTPUT_ENDS_HERE"
  @test_result_payload = {:type => 'task', :task_data => {:results => {:stdout => std_out}}, guid: 'task_112233', suite_guid: 'suite_foo'}
end

When(/^the result is processed by the keeper$/) do
  TEF::CukeKeeper.callback.call(create_mock_delivery_info, create_mock_properties, @test_result_payload, create_mock_logger)
end

Then(/^the result's information is stored$/) do
  scenario_attributes = TEF::CukeKeeper::Models::Scenario.column_names
  scenario = TEF::CukeKeeper::Models::Scenario.first

  scenario_attributes.each do |attribute|
    expect(scenario.send(attribute)).to_not be_nil
  end
end
