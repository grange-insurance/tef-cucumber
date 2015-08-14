require 'tef/cuke_keeper/version'
require 'tef/cuke_keeper/scenario_parser'
require 'tef/cuke_keeper/feature_parser'
require 'tef/cuke_keeper/json_parser'
require 'tef/cuke_keeper/models/test_suite'
require 'tef/cuke_keeper/models/feature'
require 'tef/cuke_keeper/models/scenario'
require 'json'


module TEF
  module CukeKeeper

    def self.callback
      lambda { |delivery_info, properties, payload, logger|

        case payload[:type]
          when 'task'
            handle_task_message(delivery_info, properties, payload, logger)
          when 'suite_update'
            handle_suite_update_message(delivery_info, properties, payload, logger)
          when 'suite_creation'
            handle_suite_creation_message(delivery_info, properties, payload, logger)
          when 'suite_stop'
            handle_suite_stop_message(delivery_info, properties, payload, logger)
          else
            logger.warn "Do not know how to handle a #{payload[:type]} message"
        end
      }
    end


    private


    def self.handle_task_message(delivery_info, properties, payload, logger)

      raise(ArgumentError, 'No task data found in message payload') unless payload[:task_data]
      raise(ArgumentError, 'No results found in the task data') unless payload[:task_data][:results].is_a?(Hash)

      save_task_result(payload, logger)

      if payload[:suite_guid]
        create_suite_model_if_needed(payload)
        check_for_suite_completion(payload[:suite_guid], logger)
      end

      logger.debug "Saved results for task #{payload[:guid]}"
    end

    def self.handle_suite_update_message(delivery_info, properties, payload, logger)
      associate_saved_results(payload[:suite_guid], payload[:task_ids])
      create_placeholder_scenarios(payload[:suite_guid], payload[:task_ids])
    end

    def self.handle_suite_creation_message(delivery_info, properties, payload, logger)
      logger.warn 'No task ids found in creation request' if (payload[:task_ids].nil? || payload[:task_ids].empty?)

      suite_guid = payload[:suite_guid]
      suite = suite_model_for(suite_guid)

      suite_data = {requested_time: payload[:requested_time],
                    finished_time: payload[:finished_time],
                    name: payload[:name],
                    env: payload[:env],
                    complete: payload[:complete],
      }

      # This could happen if a test result for a suite arrives before the creation request does or if
      # multiple creation requests are sent
      if suite
        logger.warn "Suite #{suite_guid} has already been created"
        update_suite_model(suite_guid, suite_data)
      else
        create_suite_model(suite_guid, suite_data)
      end


      associate_saved_results(payload[:suite_guid], payload[:task_ids])
      create_placeholder_scenarios(payload[:suite_guid], payload[:task_ids]) if payload[:task_ids]
      check_for_suite_completion(payload[:suite_guid], logger)
    end

    def self.create_suite_model(suite_guid, suite_data = {})
      suite = Models::TestSuite.new
      suite.guid = suite_guid
      suite.name = suite_data[:name]
      suite.complete = suite_data[:complete] || false

      time = suite_data[:requested_time] || DateTime.now.to_s
      suite.requested_time = DateTime.parse(time)

      suite.save

      suite
    end

    def self.update_suite_model(suite_guid, suite_data)
      suite = suite_model_for(suite_guid)

      suite.name = suite_data[:name] unless suite_data[:name].nil?
      suite.env = suite_data[:env] unless suite_data[:env].nil?
      suite.complete = suite_data[:complete] unless suite_data[:complete].nil?
      suite.requested_time = DateTime.parse(suite_data[:requested_time]) unless suite_data[:requested_time].nil?
      suite.finished_time = DateTime.parse(suite_data[:finished_time]) unless suite_data[:finished_time].nil?

      suite.save

      suite
    end

    def self.handle_suite_stop_message(delivery_info, properties, payload, logger)
      suite_guid = payload[:suite_guid]
      suite = suite_model_for(suite_guid)

      unless suite
        logger.warn "No suite #{suite_guid} found to stop."
        return
      end

      suite.finished_time = DateTime.now

      suite_scenarios = Models::Scenario.where('suite_guid = :suite_guid', suite_guid: suite_guid)
      unfinished_scenarios = suite_scenarios.where('done = :complete', complete: false)
      suite.complete = unfinished_scenarios.empty?

      suite.save
    end

    def self.parse_result(task_hash, logger)
      raise(ArgumentError, 'No stdout data found in the results') unless task_hash[:task_data][:results][:stdout]

      start_marker ='JSON_EXPANDED_FORMATTER_CONSUMABLE_OUTPUT_STARTS_HERE'
      end_marker = 'JSON_EXPANDED_FORMATTER_CONSUMABLE_OUTPUT_ENDS_HERE'

      result_output = task_hash[:task_data][:results][:stdout]
      json_match = result_output.match(/#{start_marker}(.*)#{end_marker}/m)

      raise(ArgumentError, "Could not find formatter output in: #{result_output}") unless json_match

      json_results = json_match[1]

      parser = CucumberJsonParser.new(json_results)

      {feature: parser.features.first, scenario: parser.features.first.scenarios.first}
    end

    def self.save_task_result(task_hash, logger)
      parsed_result = parse_result(task_hash, logger)

      scenario_model = get_scenario_model_for(task_hash[:guid])

      scenario_model.feature = get_associated_feature(parsed_result[:feature], task_hash[:suite_guid])
      scenario_model.name = parsed_result[:scenario].name
      scenario_model.line_number = determine_line_for(parsed_result[:scenario])
      scenario_model.steps = parsed_result[:scenario].steps
      scenario_model.status = parsed_result[:scenario].status
      scenario_model.exception = parsed_result[:scenario].error_message unless parsed_result[:scenario].passed?
      scenario_model.task_guid = task_hash[:guid]
      scenario_model.suite_guid = task_hash[:suite_guid]
      scenario_model.runtime = parsed_result[:scenario].runtime
      scenario_model.end_time = DateTime.now
      scenario_model.done = true

      scenario_model.save
    end

    def self.associate_saved_results(suite_guid, task_ids)
      associated_scenarios = Models::Scenario.where('task_guid in (:task_guids)', task_guids: task_ids)
      associated_scenarios.update_all(suite_guid: suite_guid)
    end

    def self.create_placeholder_scenarios(suite_id, task_ids)
      task_ids.each do |task_id|
        scenario_model = scenario_model_for(task_id)

        # One could already exist depending on message arrival timing (e.g. a result arrives
        # before it's placeholder was made), in which case nothing else needs to be done
        unless scenario_model
          scenario_model = Models::Scenario.new

          scenario_model.suite_guid = suite_id
          scenario_model.task_guid = task_id
          scenario_model.done = false

          scenario_model.save
        end
      end
    end

    def self.check_for_suite_completion(suite_guid, logger)
      # suite_scenarios = Models::Scenario.joins(:feature).where('suite_guid = :suite_guid', suite_guid: suite_guid)
      suite_scenarios = Models::Scenario.where('suite_guid = :suite_guid', suite_guid: suite_guid)
      logger.debug "suite_scenarios: #{suite_scenarios.count}"
      unfinished_scenarios = suite_scenarios.where('done = :complete', complete: false)
      logger.debug "unfinished scenarios: #{unfinished_scenarios.count}"
      logger.debug "done?: #{unfinished_scenarios.count == 0}"

      # todo - Assuming, for the moment, that the suite will always have been created by now. Will not necessarily be the case.
      associated_suite = suite_model_for(suite_guid)

      if unfinished_scenarios.empty?
        associated_suite.finished_time = DateTime.now
        logger.info "Suite #{suite_guid} finished at #{associated_suite.finished_time}"
      end

      associated_suite.complete = unfinished_scenarios.empty?

      associated_suite.save
    end

    def self.get_associated_feature(parsed_feature, suite_guid)
      feature_model_for(parsed_feature, suite_guid) || create_feature_model_for(parsed_feature, suite_guid)
    end

    def self.get_scenario_model_for(task_guid)
      # A placeholder record may or may not have already been created depending on message timing.
      scenario_model_for(task_guid) || Models::Scenario.new
    end

    def self.create_suite_model_if_needed(task_hash)
      create_suite_model(task_hash[:suite_guid]) unless suite_model_for(task_hash[:suite_guid])
    end

    def self.suite_model_for(suite_guid)
      suite_guid ? Models::TestSuite.where('guid = ?', suite_guid).first : nil
    end

    def self.scenario_model_for(task_id)
      task_id ? Models::Scenario.where('task_guid = ?', task_id).first : nil
    end

    def self.feature_model_for(parsed_feature, suite_guid)
      # todo - Why search on the feature's name? It's not unique and the file path already is.
      db_query = 'name = :feature_name AND filename = :feature_path AND suite_guid = :suite_guid'
      query_data = {feature_name: parsed_feature.name, feature_path: parsed_feature.path, suite_guid: suite_guid}

      Models::Feature.where(db_query, query_data).first
    end

    def self.create_feature_model_for(parsed_feature, suite_guid)
      feature_model = Models::Feature.new

      feature_model.suite_guid = suite_guid
      feature_model.filename = parsed_feature.path
      feature_model.name = parsed_feature.name
      feature_model.save

      feature_model
    end

    def self.determine_line_for(result)
      result.outline? ? result.row_no : result.line_no
    end

    def self.tef_env
      !ENV['TEF_ENV'].nil? ? ENV['TEF_ENV'].downcase : 'dev'
    end

    def self.tef_config
      !ENV['TEF_CUKE_KEEPER_DB_CONFIG'].nil? ? ENV['TEF_CUKE_KEEPER_DB_CONFIG'] : "#{File.dirname(__FILE__)}/../../config"
    end

    def self.init_db(db_config_file = nil)
      ActiveRecord::Base.time_zone_aware_attributes = true
      ActiveRecord::Base.default_timezone = :local

      db_config_file ||= "#{tef_config}/database_#{tef_env}.yml"
      db_config = YAML.load(File.open(db_config_file))

      ActiveRecord::Base.establish_connection(db_config)
      ActiveRecord::Base.table_name_prefix = "keeper_#{tef_env}_"
      ActiveRecord::Base.logger = Logger.new(File.open('database.log', 'a'))
    end

  end
end
