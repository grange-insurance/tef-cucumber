def update_test_output(message, attribute, value)
  output = message[:task_data][:results][:stdout]

  start_marker ='JSON_EXPANDED_FORMATTER_CONSUMABLE_OUTPUT_STARTS_HERE'
  end_marker = 'JSON_EXPANDED_FORMATTER_CONSUMABLE_OUTPUT_ENDS_HERE'

  json_output = output.match(/#{start_marker}(.*)#{end_marker}/m)[1]
  json_hash = JSON.parse(json_output, symbolize_names: true)


  case attribute
    when :name
      json_hash.first[:elements].first[:name] = value
    when :exception
      failing_step = "{\"keyword\":\"* \",\"name\":\"explode\",\"line\":5,\"match\":{\"location\":\"features/step_definitions/test_step_defs.rb:5\"},\"result\":{\"status\":\"failed\",\"error_message\":\"Boom!!! (RuntimeError)\\n./features/step_definitions/test_step_defs.rb:6:in `/^explode$/'\\nfeatures/more_features/test_feature_2.feature:5:in `* explode'\",\"duration\":0}}"
      failing_step = JSON.parse(failing_step, symbolize_names: true)
      failing_step[:result][:error_message] = value

      json_hash.first[:elements].first[:steps].unshift(failing_step)
    when :line_number
      json_hash.first[:elements].first[:line] = value
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
