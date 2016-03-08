require 'spec_helper'


describe 'CukeWorker, Unit' do

  let(:clazz) { TEF::Worker::CukeWorker }


  it_should_behave_like 'a strictly configured component'


  describe 'instance level' do

    let(:mock_in_queue) { create_mock_queue }
    let(:configuration) { {root_location: @default_file_directory,
                           logger: create_mock_logger,
                           in_queue: mock_in_queue,
                           output_exchange: create_mock_exchange,
                           manager_queue: create_mock_queue} }
    let(:worker) { clazz.new(configuration) }


    it_should_behave_like 'a logged component, unit level'
    it_should_behave_like 'a worker component, unit level'


    describe 'initial setup' do

      it 'defaults to being a cucumber worker' do
        configuration.delete(:worker_type)
        worker = clazz.new(configuration)

        expect(worker.worker_type).to eq('cucumber')
      end


      # todo - several of these seems like they should be in the shared worker specs

      it 'will complain if not provided a queue from which to receive tasks' do
        configuration.delete(:in_queue)

        expect { clazz.new(configuration) }.to raise_error(ArgumentError, /must have/i)
      end

      it 'will complain if not provided an exchange to which to post task results' do
        configuration.delete(:output_exchange)

        expect { clazz.new(configuration) }.to raise_error(ArgumentError, /must have/i)
      end

      it 'will complain if not provided a manager to which to post status updates' do
        configuration.delete(:manager_queue)

        expect { clazz.new(configuration) }.to raise_error(ArgumentError, /must have/i)
      end

    end

  end
end
