require 'spec_helper'
require 'bunny'


describe 'Queuebert, Integration' do

  let(:clazz) { TEF::Queuebert::Queuebert }
  let(:mock_logger) { create_mock_logger }
  let(:mock_channel) { create_mock_channel }
  let(:fake_publisher) { create_fake_publisher(mock_channel) }
  let(:configuration) { {logger: mock_logger} }
  let(:test_request) { {name: 'Test request',
                        dependencies: ["foo", "bar"],
                        root_location: @default_file_directory,
                        tests: ['some', 'tests']} }

  it_should_behave_like 'a logged component, integration level'
  it_should_behave_like 'a service component, integration level'
  it_should_behave_like 'a receiving component, integration level', [:in_queue]
  it_should_behave_like 'a sending component, integration level', [:manager_queue, :keeper_queue]
  it_should_behave_like 'a wrapper component, integration level', [:in_queue, :output_exchange]


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

  it 'logs when it encounters a bad feature file' do
    test_file = "#{@default_file_directory}/a_bad_feature.feature"
    File.open(test_file, 'w') { |file| file.write("Feature: Syntactically invalid \n @foo") }

    test_request[:directories] = ['.']
    configuration[:in_queue] = fake_publisher
    queuebert = clazz.new(configuration)

    begin
      queuebert.start
      fake_publisher.call(create_mock_delivery_info, create_mock_properties, test_request.to_json)

      expect(mock_logger).to have_received(:warn).with("Could not parse file: #{@default_file_directory}/./a_bad_feature.feature")
    ensure
      queuebert.stop
    end
  end

end
