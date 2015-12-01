require 'spec_helper'


describe 'Runner, Unit' do

  let(:clazz) { CukeRunner::Runner }


  it_should_behave_like 'a strictly configured component'


  describe 'class level' do

    it 'has a special way of doing work' do
      expect(clazz.instance_method(:work).owner).to eq(clazz)
    end

    it 'also requires a task to work on' do
      expect(clazz.instance_method(:work).arity).to eq(1)
    end

  end


  describe 'instance level' do

    let(:mock_executor) { mock = double('TestExecutor')
                          allow(mock).to receive(:execute).and_return(some_keys: 'some_values')
                          mock }
    let(:command_line_generator) { mock = double('TestCLG')
                                   allow(mock).to receive(:generate_command_line).and_return('cucumber')
                                   mock }
    let(:configuration) { {executor: mock_executor, command_line_generator: command_line_generator} }
    let(:runner) { clazz.new(configuration) }

    # todo - It would be great if changes to this baseline data didn't break every test. Perhaps change
    # how the tests are checking for stuff?
    let(:default_cucumber_options) { {formatters: {'Cucumber::Formatter::JsonExpanded' => ''}, options: ['--expand']} }
    let(:baseline_task_data) { {command: 'cucumber', cucumber_options: default_cucumber_options} }
    let(:test_task) { {task_data: {}} }


    # That there isn't a good way to verify this without duplicating the tests themselves
    # leads me to believe that there is some better design that we could be using...
    describe 'behaving the same way as its parent class' do

      it_should_behave_like 'a logged component, unit level'


      it 'needs task data in order to work the task' do
        test_task.delete(:task_data)

        expect { runner.work(test_task) }.to raise_error(ArgumentError, /data/)
      end

      it 'executes the worked task' do
        runner.work(test_task)

        expect(mock_executor).to have_received(:execute).once
      end

      it 'passes along to the executor all important task data' do
        relevant_task_data = {working_directory: 'some/dir', task_command: 'FOO.exe', other_data: {more: 'stuff'}}
        task = {task_data: relevant_task_data, other_data: 'stuff'}

        runner.work(task)

        expect(mock_executor).to have_received(:execute).with(hash_including(relevant_task_data)).once
      end

      it 'returns the output of the task execution' do
        output = runner.work(test_task)

        expect(output).to eq(some_keys: 'some_values')
      end
    end

    describe 'new behavior' do

      it 'executes a cucumber command by default' do
        test_task[:task_data].delete(:command)

        runner.work(test_task)

        expect(mock_executor).to have_received(:execute).with(baseline_task_data.merge(command: 'cucumber')).once
      end

      it 'does not modify the original task' do
        test_task[:task_data].delete(:command)

        # A command key is added by default if one does not exist (see other spec)
        runner.work(test_task)

        expect(test_task[:task_data]).to_not have_key(:command)
      end

      it 'executes a different command, if provided' do
        explicit_command = 'special cucumber command'
        test_task[:task_data][:command] = explicit_command

        runner.work(test_task)

        expect(mock_executor).to have_received(:execute).with(baseline_task_data.merge(command: explicit_command)).once
      end

      it 'customizes the cucumber command based on options, if provided' do
        options = {profiles: ['unit_test', 'dev'], tags: ['@smoke'], formatters: {'json' => :stdout}}
        test_task[:task_data][:cucumber_options] = options

        runner.work(test_task)

        expect(command_line_generator).to have_received(:generate_command_line).with(default_cucumber_options.merge(options)).once
      end

      it 'uses the Cucumber::Formatter::JsonExpanded formatter with STDOUT if no other formatter options are specified' do
        test_task[:task_data][:cucumber_options].delete(:formatters) if test_task[:task_data][:cucumber_options]

        runner.work(test_task)

        expect(command_line_generator).to have_received(:generate_command_line).with(default_cucumber_options.merge(formatters: {'Cucumber::Formatter::JsonExpanded' => ''})).once
      end

      it "uses the '--expand' option if no other cucumber options are specified" do
        test_task[:task_data][:cucumber_options].delete(:options) if test_task[:task_data][:cucumber_options]

        runner.work(test_task)

        expect(command_line_generator).to have_received(:generate_command_line).with(baseline_task_data[:cucumber_options].merge(options: ['--expand'])).once
      end

      it 'does not use the default if a formatter option is provided' do
        test_task[:task_data][:cucumber_options] = {formatters: :some_formatters}

        runner.work(test_task)

        expect(command_line_generator).to have_received(:generate_command_line).with(default_cucumber_options.merge(formatters: :some_formatters)).once
      end

      it 'will add to the existing options, if provided, when using the default formatter' do
        test_task[:task_data][:cucumber_options] = {foo: 'bar'}

        runner.work(test_task)

        expect(command_line_generator).to have_received(:generate_command_line).with(default_cucumber_options.merge(foo: 'bar')).once
      end

      it 'will create options, if none are provided, when using the default formatter' do
        test_task[:task_data].delete(:cucumber_options)

        runner.work(test_task)

        expect(command_line_generator).to have_received(:generate_command_line).with(default_cucumber_options).once
      end

      it 'can execute cucumber with bundler' do
        gemfile_to_use = 'gemfile'
        test_task[:task_data][:gemfile] = gemfile_to_use

        runner.work(test_task)

        expect(mock_executor).to have_received(:execute).with(baseline_task_data.merge(gemfile: gemfile_to_use, env_vars: {'BUNDLE_GEMFILE' => gemfile_to_use}, command: 'bundle exec cucumber')).once
      end

      it 'will add to the existing environmental variables, if provided, when using bundler' do
        gemfile_to_use = 'gemfile'
        test_task[:task_data][:gemfile] = gemfile_to_use
        test_task[:task_data][:env_vars] = {'FOO' => 'BAR'}

        runner.work(test_task)

        expect(mock_executor).to have_received(:execute).with(baseline_task_data.merge(gemfile: gemfile_to_use, env_vars: {'FOO' => 'BAR', 'BUNDLE_GEMFILE' => gemfile_to_use}, command: 'bundle exec cucumber')).once
      end

      it 'will create environmental variables, if none are provided, when using bundler' do
        gemfile_to_use = 'gemfile'
        test_task[:task_data][:gemfile] = gemfile_to_use
        test_task[:task_data].delete(:env_vars)

        runner.work(test_task)

        expect(mock_executor).to have_received(:execute).with(baseline_task_data.merge(gemfile: gemfile_to_use, env_vars: {'BUNDLE_GEMFILE' => gemfile_to_use}, command: 'bundle exec cucumber')).once
      end

      it 'executes cucumber without bundler' do
        test_task[:task_data].delete(:gemfile)

        runner.work(test_task)

        expect(mock_executor).to have_received(:execute).with(baseline_task_data).once
      end

      it "treats the provided gemfile as relative to the task's working directory (if one is provided)" do
        working_directory = 'foo'
        gemfile_to_use = 'bar'
        test_task[:task_data][:gemfile] = gemfile_to_use
        test_task[:task_data][:working_directory] = working_directory

        runner.work(test_task)

        expect(mock_executor).to have_received(:execute).with(baseline_task_data.merge(working_directory: working_directory, gemfile: gemfile_to_use, env_vars: {'BUNDLE_GEMFILE' => "#{working_directory}/#{gemfile_to_use}"}, command: 'bundle exec cucumber')).once

        test_task[:task_data].delete(:working_directory)
        runner.work(test_task)

        expect(mock_executor).to have_received(:execute).with(baseline_task_data.merge(gemfile: gemfile_to_use, env_vars: {'BUNDLE_GEMFILE' => gemfile_to_use}, command: 'bundle exec cucumber')).once
      end

    end
  end
end
