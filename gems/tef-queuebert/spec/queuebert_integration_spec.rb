require 'spec_helper'
require 'bunny'


def default_options
  {}
end


describe 'Queuebert, Integration' do

  clazz = TEF::Queuebert::Queuebert

  it_should_behave_like 'a logged component, integration level' do
    let(:clazz) { clazz }
    let(:configuration) { default_options }
  end

  it_should_behave_like 'a service component, integration level' do
    let(:clazz) { clazz }
    let(:configuration) { default_options }
  end

  it_should_behave_like 'a receiving component, integration level', clazz, default_options, [:suite_request_queue]
  it_should_behave_like 'a sending component, integration level', clazz, default_options, [:manager_queue, :keeper_queue]


  before(:each) do
    @options = default_options
  end


  it 'uses its own logging object when creating its queuer' do
    mock_logger = create_mock_logger
    @options[:logger] = mock_logger

    queuebert = clazz.new(@options)

    begin
      queuebert.start

      expect(queuebert.instance_variable_get(:@queuer).logger).to eq(mock_logger)
    ensure
      queuebert.stop
    end
  end

end
