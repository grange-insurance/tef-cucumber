require 'spec_helper'
require 'cuke_commander'
require 'task_runner'

describe 'Runner, Integration' do

  let(:clazz) { CukeRunner::Runner }


  describe 'instance level' do

    let(:executor) { mock = double('TestExecutor')
                     allow(mock).to receive(:execute).and_return(some_keys: 'some_values')
                     mock }
    let(:command_line_generator) { mock = double('TestCLG')
                                   allow(mock).to receive(:generate_command_line).and_return('cucumber')
                                   mock }
    let(:configuration) { {executor: executor,
                           command_line_generator: command_line_generator} }
    let(:runner) { clazz.new(configuration) }

    let(:baseline_task_data) { {command: 'cucumber', cucumber_options: {formatters: {'json' => :stdout}}} }
    let(:test_task) { {task_data: {}} }


    it "command line generator defaults to the cuke_commander's generator if one is not provided" do
      configuration.delete(:command_line_generator)
      runner = clazz.new(configuration)

      expect(runner.instance_variable_get(:@command_line_generator)).to be_a(CukeCommander::CLGenerator)
    end

    it 'defaults to a basic executor if one is not provided' do
      configuration.delete(:executor)
      runner = clazz.new(configuration)

      expect(runner.instance_variable_get(:@executor)).to be_a(TaskRunner::Executor)
    end

    it 'uses its own logging object when providing a default executor' do
      mock_logger = create_mock_logger
      configuration[:logger] = mock_logger
      configuration.delete(:executor)

      runner = clazz.new(configuration)

      expect(runner.instance_variable_get(:@executor).logger).to eq(mock_logger)
    end

    # That there isn't a good way to verify this without duplicating the tests themselves
    # leads me to believe that there is some better design that we could be using...
    describe 'behaving the same way as its parent class' do

      it_should_behave_like 'a logged component, integration level'

    end
  end
end
