require 'spec_helper'

describe 'CukeWorker, Unit' do

  clazz = TEF::Worker::CukeWorker


  it_should_behave_like 'a strictly configured component', clazz


  describe 'instance level' do

    before(:each) do
      @mock_in_queue = create_mock_queue

      @options = {root_location: @default_file_directory, logger: create_mock_logger, in_queue: @mock_in_queue, out_queue: create_mock_queue, manager_queue: create_mock_queue}
      @worker = clazz.new(@options)
    end

    it_should_behave_like 'a logged component, unit level' do
      let(:clazz) { clazz }
      let(:configuration) { @options }
    end

    it_should_behave_like 'a worker component, unit level', clazz do
      let(:configuration) { @options }
    end


    describe 'initial setup' do

      it 'defaults to being a cucumber worker' do
        @options.delete(:worker_type)
        worker = clazz.new(@options)

        expect(worker.worker_type).to eq('cucumber')
      end


      # todo - several of these seems like they should be in the shared worker specs

      it 'will complain if not provided a queue from which to receive tasks' do
        @options.delete(:in_queue)

        expect { clazz.new(@options) }.to raise_error(ArgumentError, /must have/i)
      end

      it 'will complain if not provided a queue to which to post task results' do
        @options.delete(:out_queue)

        expect { clazz.new(@options) }.to raise_error(ArgumentError, /must have/i)
      end

      it 'will complain if not provided a manager to which to post status updates' do
        @options.delete(:manager_queue)

        expect { clazz.new(@options) }.to raise_error(ArgumentError, /must have/i)
      end

    end

  end
end
