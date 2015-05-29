require 'cuke_commander'

module CukeRunner
  class Runner < TaskRunner::Runner

    def initialize(options)
      super(options)

      @command_line_generator = options.fetch(:command_line_generator, CukeCommander::CLGenerator.new)
    end

    def work(task)
      task = Marshal.load(Marshal.dump(task))
      @logger.info("TaskRunner received task: #{task}")
      raise(ArgumentError, ':task must include a :task_data key') unless task.has_key? :task_data


      task[:task_data][:cucumber_options] ||= {}
      task[:task_data][:cucumber_options][:formatters] ||= {'Cucumber::Formatter::JsonExpanded' => ''}
      task[:task_data][:cucumber_options][:options] ||= ['--expand'] # todo - add expand flag whenever default formatter is used

      unless task[:task_data][:command]
        @logger.info("need to generate command line...")
        commandline = @command_line_generator.generate_command_line(task[:task_data][:cucumber_options])

        task[:task_data][:command] = commandline
      end

      if task[:task_data][:gemfile]
        @logger.info("need to deal with gemfile...")

        task[:task_data][:env_vars] ||= {}

        if task[:task_data][:working_directory]
          task[:task_data][:env_vars]['BUNDLE_GEMFILE'] = "#{task[:task_data][:working_directory]}/#{task[:task_data][:gemfile]}"
        else
          task[:task_data][:env_vars]['BUNDLE_GEMFILE'] = task[:task_data][:gemfile]
        end

        task[:task_data][:command] = "bundle exec #{task[:task_data][:command]}"
      else
        @logger.info("Removing existing gemfile...")
        ENV.delete('BUNDLE_GEMFILE')
      end

      @logger.info("tossing up to inherited work process...")

      super(task)
    end

  end
end
