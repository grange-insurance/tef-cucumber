require 'spec_helper'
require 'bunny'


describe 'Queuebert, Integration' do

  let(:clazz) { TEF::Queuebert::Queuebert }
  let(:configuration) { {} }

  it_should_behave_like 'a logged component, integration level'
  it_should_behave_like 'a service component, integration level'
  it_should_behave_like 'a receiving component, integration level', [:suite_request_queue]
  it_should_behave_like 'a sending component, integration level', [:manager_queue, :keeper_queue]
  it_should_behave_like 'a wrapper component, integration level', [:suite_request_queue, :output_exchange]


  it 'uses its own logging object when creating its queuer' do
    mock_logger = create_mock_logger
    configuration[:logger] = mock_logger

    queuebert = clazz.new(configuration)

    begin
      queuebert.start

      expect(queuebert.instance_variable_get(:@queuer).logger).to eq(mock_logger)
    ensure
      queuebert.stop
    end
  end

end
