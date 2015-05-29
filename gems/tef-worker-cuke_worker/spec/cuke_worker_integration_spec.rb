require 'spec_helper'
require 'cuke_runner'

describe 'CukeWorker, Integration' do

  clazz = TEF::Worker::CukeWorker


  before(:each) do
    @mock_manager_queue = create_mock_queue
    @in_queue = create_mock_queue

    @options = {root_location: @default_file_directory, in_queue: @in_queue, out_queue: create_mock_queue, manager_queue: @mock_manager_queue}
    @worker = clazz.new(@options)
  end

  it_should_behave_like 'a logged component, integration level' do
    let(:clazz) { clazz }
    let(:configuration) { @options }
  end

  it_should_behave_like 'a worker component, integration level' do
    let(:clazz) { clazz }
    let(:configuration) { @options }
  end


  it 'runner defaults to a cuke runner if one is not provided' do
    @options.delete(:runner)
    component = clazz.new(@options)

    expect(component.instance_variable_get(:@runner)).to be_a(CukeRunner::Runner)
  end

  it 'should be listening to its inbound queue once it has been started' do
    begin
      @worker.start

      expect(@in_queue).to have_received(:subscribe_with)
    ensure
      @worker.stop
    end
  end

end
