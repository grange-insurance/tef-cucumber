require 'spec_helper'
require 'cuke_commander'
require 'task_runner'

describe 'Runner, Integration' do

  clazz = CukeRunner::Runner


  describe 'instance level' do
    before(:each) do
      @executor = double('TestExecutor')
      allow(@executor).to receive(:execute).and_return(some_keys: 'some_values')

      @command_line_generator = double('TestCLG')
      allow(@command_line_generator).to receive(:generate_command_line).and_return('cucumber')

      @options = {executor: @executor, command_line_generator: @command_line_generator}
      @runner = clazz.new(@options)

      @baseline_task_data = {command: 'cucumber', cucumber_options: {formatters: {'json' => :stdout}}}
      @test_task = {task_data: {}}
    end


    it "command line generator defaults to the cuke_commander's generator if one is not provided" do
      @options.delete(:command_line_generator)
      runner = clazz.new(@options)

      expect(runner.instance_variable_get(:@command_line_generator)).to be_a(CukeCommander::CLGenerator)
    end

    it 'defaults to a basic executor if one is not provided' do
      @options.delete(:executor)
      runner = clazz.new(@options)

      expect(runner.instance_variable_get(:@executor)).to be_a(TaskRunner::Executor)
    end

    it 'uses its own logging object when providing a default executor' do
      mock_logger = create_mock_logger
      @options[:logger] = mock_logger
      @options.delete(:executor)

      runner = clazz.new(@options)

      expect(runner.instance_variable_get(:@executor).logger).to eq(mock_logger)
    end

    # That there isn't a good way to verify this without duplicating the tests themselves
    # leads me to believe that there is some better design that we could be using...
    describe 'behaving the same way as its parent class' do


      it_should_behave_like 'a logged component, integration level' do
        let(:clazz) { clazz }
        let(:configuration) { @options }
      end

    end
  end
end
