def generic_test_output
  "Test 2 is happening\nBundler mode: dev\nJSON_EXPANDED_FORMATTER_CONSUMABLE_OUTPUT_STARTS_HERE[\n  {\n    \"keyword\": \"Feature\",\n    \"name\": \"Test feature 2\",\n    \"line\": 1,\n    \"description\": \"\",\n    \"id\": \"test-feature-2\",\n    \"uri\": \"features/more_features/test_feature_2.feature\",\n    \"elements\": [\n      {\n        \"keyword\": \"Scenario\",\n        \"name\": \"Test 2\",\n        \"line\": 3,\n        \"description\": \"\",\n        \"id\": \"test-feature-2;test-2\",\n        \"type\": \"scenario\",\n        \"steps\": [\n          {\n            \"keyword\": \"* \",\n            \"name\": \"echo \\\"Test 2 is happening\\\"\",\n            \"line\": 4,\n            \"match\": {\n              \"arguments\": [\n                {\n                  \"offset\": 6,\n                  \"val\": \"Test 2 is happening\"\n                }\n              ],\n              \"location\": \"features/step_definitions/test_step_defs.rb:1\"\n            },\n            \"result\": {\n              \"status\": \"passed\",\n              \"duration\": 123000000\n            }\n          },\n          {\n            \"keyword\": \"* \",\n            \"name\": \"explode\",\n            \"line\": 5,\n            \"match\": {\n              \"location\": \"features/step_definitions/test_step_defs.rb:5\"\n            },\n            \"result\": {\n              \"status\": \"failed\",\n              \"error_message\": \"Boom!!! (RuntimeError)\\n./features/step_definitions/test_step_defs.rb:6:in `/^explode$/'\\nfeatures/more_features/test_feature_2.feature:5:in `* explode'\",\n              \"duration\": 0\n            }\n          }\n        ]\n      }\n    ]\n  }\n]JSON_EXPANDED_FORMATTER_CONSUMABLE_OUTPUT_ENDS_HERE"
end

def update_test_output(type = :scenario, message, attribute, value)
  output = message[:task_data][:results][:stdout]

  start_marker ='JSON_EXPANDED_FORMATTER_CONSUMABLE_OUTPUT_STARTS_HERE'
  end_marker = 'JSON_EXPANDED_FORMATTER_CONSUMABLE_OUTPUT_ENDS_HERE'

  json_output = output.match(/#{start_marker}(.*)#{end_marker}/m)[1]
  json_hash = JSON.parse(json_output, symbolize_names: true)

  if type == :scenario
    json_hash.first[:elements].first[:type] = 'scenario'
  else
    json_hash.first[:elements].first[:type] = 'scenario_outline'
  end


  case attribute
    when :name
      json_hash.first[:elements].first[:name] = value
    when :exception
      failing_step = "{\"keyword\":\"* \",\"name\":\"explode\",\"line\":5,\"match\":{\"location\":\"features/step_definitions/test_step_defs.rb:5\"},\"result\":{\"status\":\"failed\",\"error_message\":\"Boom!!! (RuntimeError)\\n./features/step_definitions/test_step_defs.rb:6:in `/^explode$/'\\nfeatures/more_features/test_feature_2.feature:5:in `* explode'\",\"duration\":0}}"
      failing_step = JSON.parse(failing_step, symbolize_names: true)
      failing_step[:result][:error_message] = value

      json_hash.first[:elements].first[:steps].unshift(failing_step)
    when :line_number
      if type == :scenario
        json_hash.first[:elements].first[:line] = value
      else
        json_hash.first[:elements].first[:row_line] = value
      end
    when :runtime
      num_steps = json_hash.first[:elements].first[:steps].count
      time_portion = (value * 1000000000.0) / num_steps

      json_hash.first[:elements].first[:steps].each do |step|
        step[:result][:duration] = time_portion
      end
    when :status
      case value
        when 'passing'
          json_hash.first[:elements].first[:steps].each do |step|
            step[:result][:status] = 'passed'
          end
        when 'failing'
          json_hash.first[:elements].first[:steps].each do |step|
            step[:result][:status] = 'passed'
          end

          json_hash.first[:elements].first[:steps].last[:result][:status] = 'failed'
        when 'pending'
          json_hash.first[:elements].first[:steps].each do |step|
            step[:result][:status] = 'skipped'
          end

          json_hash.first[:elements].first[:steps].first[:result][:status] = 'pending'
        when 'undefined'
          json_hash.first[:elements].first[:steps].each do |step|
            step[:result][:status] = 'skipped'
          end

          json_hash.first[:elements].first[:steps].first[:result][:status] = 'undefined'
        else
          raise("Don't know how to update test data for a '#{attribute}' of '#{value}'")
      end

    when :suite_guid
      message[:suite_guid] = value
    when :task_guid
      message[:guid] = value
    when :steps
      generic_step = "{\"keyword\":\"* \",\"name\":\"explode\",\"line\":5,\"match\":{\"location\":\"features/step_definitions/test_step_defs.rb:5\"},\"result\":{\"status\":\"passed\",\"duration\":0}}"

      json_hash.first[:elements].first[:steps] = []

      value.split("\n").each do |step|
        pieces = step.split
        keyword = pieces.shift

        other = JSON.parse(generic_step, symbolize_names: true)
        other[:name] = pieces.join(' ')
        other[:keyword] = "#{keyword} "

        json_hash.first[:elements].first[:steps] << other
      end
  end

  output.sub!(/#{start_marker}.*#{end_marker}/m, "#{start_marker}#{json_hash.to_json}#{end_marker}")
end
