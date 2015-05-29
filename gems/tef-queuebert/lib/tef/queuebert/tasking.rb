require 'securerandom'


module TEF
  module Queuebert
    module Tasking

      def self.create_tasks_for(meta_data, tests)
        raise(ArgumentError, "Can only create tasks from an array. Got #{tests.class}") unless tests.is_a?(Array)
        raise(ArgumentError, "Task meta data can only be a Hash. Got #{meta_data.class}") unless meta_data.is_a?(Hash)

        Array.new.tap do |created_tasks|
          tests.each do |test_case|
            task = {
                type: 'task',
                task_type: 'cucumber',
                guid: SecureRandom.uuid,
                resources: meta_data[:dependencies],
                task_data: {cucumber_options: {file_paths: []}}
            }

            task[:task_data][:cucumber_options].merge!(meta_data[:command_line_options]) if meta_data[:command_line_options]
            task[:task_data][:cucumber_options][:file_paths] += [test_case]

            task[:priority] = meta_data[:priority] if meta_data[:priority]
            task[:time_limit] = meta_data[:time_limit] if meta_data[:time_limit]
            task[:task_data][:root_location] = meta_data[:root_location] if meta_data[:root_location]
            #todo - generate a suite guid if one is not provided
            task[:suite_guid] = meta_data[:suite_guid] if meta_data[:suite_guid]
            task[:task_data][:working_directory] = meta_data[:working_directory] if meta_data[:working_directory]
            task[:task_data][:gemfile] = meta_data[:gemfile] if meta_data[:gemfile]

            created_tasks << task
          end
        end
      end

    end
  end
end
