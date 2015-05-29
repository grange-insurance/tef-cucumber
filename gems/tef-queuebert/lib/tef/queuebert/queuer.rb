module TEF
  module Queuebert
    class Queuer < Bunny::Consumer
      attr_reader :logger

      def initialize(options)
        validate_configuration_options(options)
        configure_self(options)

        @logger.debug("Root location: #{ENV['TEF_QUEUEBERT_SEARCH_ROOT']}")

        # todo - test the ack flag being used
        super(@in_queue.channel, @in_queue, @in_queue.channel.generate_consumer_tag, false)

        set_message_action
        listen_for_messages
      end

      def valid_request?(payload)
        begin
          payload = JSON.parse(payload, symbolize_names: true)
        rescue JSON::ParserError
          return false
        end

        logger.debug "Validating parsed request: #{payload}"

        has_required_keys?(payload) &&
            has_test_keys?(payload) &&
            valid_test_directory?(payload) &&
            valid_root_location?(payload) &&
            valid_tests?(payload) &&
            valid_directories?(payload)
      end


      private


      def has_required_keys?(payload)
        required_keys = [:name, :dependencies]
        required_keys.all? { |key| payload.keys.include?(key) }
      end

      def has_test_keys?(payload)
        test_keys = [:tests, :directories, :test_directory]
        test_keys.any? { |key| payload.keys.include?(key) }
      end

      def valid_test_directory?(payload)
        payload[:test_directory].nil? || payload[:test_directory].is_a?(String)
      end

      def valid_root_location?(payload)
        payload[:root_location].nil? || payload[:root_location].is_a?(String)
      end

      def valid_tests?(payload)
        payload[:tests].nil? || payload[:tests].is_a?(Array)
      end

      def valid_directories?(payload)
        payload[:directories].nil? || payload[:directories].is_a?(Array)
      end

      def validate_configuration_options(options)
        raise(ArgumentError, 'Configuration options must have a :suite_request_queue') unless options[:suite_request_queue]
        raise(ArgumentError, 'Configuration options must have a :manager_queue') unless options[:manager_queue]
        raise(ArgumentError, 'Configuration options must have a :keeper_queue') unless options[:keeper_queue]
      end

      def configure_self(options)
        @out_queue = options[:manager_queue]
        @in_queue = options[:suite_request_queue]
        @keeper_queue = options[:keeper_queue]
        @task_creator = options.fetch(:task_creator, Tasking)
        @test_finder = options.fetch(:test_finder, Searching)
        @logger = options.fetch(:logger, Logger.new($stdout))
      end

      def set_message_action
        self.on_delivery do |delivery_info, meta, payload|

          exchange = @in_queue.channel.default_exchange
          format = '{
                      "name":                 "required",
                      "owner":                "optional",
                      "dependencies":         "required",
                      "command_line_options": "optional",
                      "root_location":        "optional",
                      "test_directory":       "required",
                      "tests":                "required(array)",
                      "directories":          "required(array)",
                      "tag_exclusions":       "optional",
                      "tag_inclusions":       "optional",
                      "path_exclusions":       "optional",
                      "path_inclusions":       "optional"
                    }'

          begin
            if valid_request?(payload)
              logger.info 'Queue request received'
              exchange.publish('Request received', :routing_key => meta.reply_to, :correlation_id => meta.correlation_id)
              create_test_suite(JSON.parse(payload, symbolize_names: true))
            else
              logger.error "Invalid queue request received: #{payload}"
              exchange.publish("Invalid request. #{format.delete(" \n")}", :routing_key => meta.reply_to, :correlation_id => meta.correlation_id)
            end
          rescue => e
            @logger.error "There was a problem while handling the message: #{e.message}:#{e.backtrace}"
          end

          @in_queue.channel.acknowledge(delivery_info.delivery_tag, false)
        end
      end

      def listen_for_messages
        # Non-blocking is the default but passing it in anyway for clarity
        @in_queue.subscribe_with(self, block: false)
      end

      def create_test_suite(request)
        meta_data = request

        root_location = request[:root_location] || ENV['TEF_QUEUEBERT_SEARCH_ROOT']
        unless root_location
          msg = "Can't determine root location. Must be provided in request or configured in ENV['TEF_QUEUEBERT_SEARCH_ROOT']."
          logger.error(msg)
          return
        end
          tests = []
#        # todo - test these nil/empty conditionals and combinations
#        if request.has_key?('tests') && !request['tests'].empty?
        if request.has_key?(:tests)
          logger.info("Adding explicit tests [#{request[:tests].join(', ')}]")
          explicit_tests = request[:tests].dup
          explicit_tests.map! { |test_path| "#{request[:test_directory]}/#{test_path}" } if request[:test_directory]

          tests.concat(explicit_tests)
        end


        filters = {}
        filters[:excluded_tags] = request[:tag_exclusions] if request[:tag_exclusions]
        filters[:included_tags] = request[:tag_inclusions] if request[:tag_inclusions]
        filters[:excluded_paths] = request[:path_exclusions] if request[:path_exclusions]
        filters[:included_paths] = request[:path_inclusions] if request[:path_inclusions]


#        if request.has_key?('directories') && !request['directories'].empty?
        if request.has_key?(:directories)
          logger.info("Searching provided directories [#{request[:directories].join(', ')}]")
          explicit_directories = request[:directories].dup
          explicit_directories.map! { |directory_path| "#{request[:test_directory]}/#{directory_path}" } if request[:test_directory]

          found_tests = @test_finder.find_test_cases(root_location, explicit_directories, filters)

          tests.concat(found_tests)
        end

        if (request[:test_directory] && request[:tests].nil? && request[:directories].nil?)
          logger.info "Searching test directory #{request[:test_directory]}"
          tests.concat(@test_finder.find_test_cases(root_location, request[:test_directory], filters))
        end

        logger.debug('creating tasks')
        tests.collect! { |test_path| File.expand_path(test_path).sub("#{Dir.pwd}/", '') }
        tests.uniq!

        # todo - still need to test and document this
        tests.collect! { |test_path| test_path.sub(/^#{request[:working_directory]}\//, '') } if request[:working_directory]
        logger.debug("created tests: #{tests}")


        created_tasks = @task_creator.create_tasks_for(meta_data, tests)

        logger.debug('forwarding tasks')
        forward_tasks(created_tasks)
        send_suite_notification(meta_data, created_tasks)
      end

      def forward_tasks(tasks)
        tasks.each do |task|
          logger.debug("forwarding task: #{task}")

          @out_queue.publish(task.to_json)
        end
      end

      # todo - could probably test this method better
      def send_suite_notification(meta_data, tasks)
        tasks = tasks.collect { |task| task[:guid] }
        reasonably_small_chunk_size = 100
        notifications = []

        tasks.each_slice(reasonably_small_chunk_size) do |id_set|
          notifications << {
              type: "suite_update",
              suite_guid: meta_data[:suite_guid],
              task_ids: id_set,
              test_count: tasks.count.to_s
          }
        end

        creation_notification = notifications.first

        # It's possible that a suite was requested that, possibly by accident, filtered out
        # all tests. A suite still needs to be created for keeper to track.
        creation_notification ||= {
            suite_guid: meta_data[:suite_guid],
            task_ids: [],
            test_count: '0'
        }

        creation_notification[:type] = "suite_creation"
        creation_notification[:name] = meta_data[:name]
        creation_notification[:owner] = meta_data[:owner]
        creation_notification[:env] = meta_data[:env]
        creation_notification[:requested_time] = DateTime.now

        notifications.each do |notification|
          @keeper_queue.publish(notification.to_json)
        end
      end

    end
  end
end
