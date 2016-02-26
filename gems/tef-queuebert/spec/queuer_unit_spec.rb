require 'spec_helper'


describe 'Queuer, Unit' do

  let(:clazz) { TEF::Queuebert::Queuer }


  describe 'class level' do

    it_should_behave_like 'a strictly configured component'

    it 'is capable of consuming from message queues' do
      expect(clazz.ancestors).to include(Bunny::Consumer)
    end

  end


  describe 'instance level' do

    let(:test_request) { {name: 'Test request',
                          dependencies: ["foo","bar"],
                          root_location: 'foo',
                          tests: ['some', 'tests'],
                          directories: ['some', 'directories']} }
    let(:mock_logger) { create_mock_logger }
    let(:mock_properties) { create_mock_properties }
    let(:mock_exchange) { create_mock_exchange }
    let(:mock_channel) { create_mock_channel(mock_exchange) }
    let(:mock_publisher) { create_mock_queue(mock_channel) }
    let(:fake_publisher) { create_fake_publisher(mock_channel) }
    let(:mock_task_creator) { mock = double('task_creator')
                              allow(mock).to receive(:create_tasks_for).and_return([])
                              mock }
    let(:mock_test_finder) { create_mock_test_finder }
    let(:configuration) { {logger: mock_logger,
                           suite_request_queue: mock_publisher,
                           output_exchange: create_mock_exchange,
                           task_creator: mock_task_creator,
                           test_finder: mock_test_finder} }
    let(:queuer) { clazz.new(configuration) }


    it_should_behave_like 'a logged component, unit level'


    describe 'initial setup' do

      it 'can be provided a test finder when created' do
        configuration[:test_finder] = 'some test finder'
        queuer = clazz.new(configuration)

        expect(queuer.instance_variable_get(:@test_finder)).to eq('some test finder')
      end

      it 'can be provided a task creator when created' do
        configuration[:task_creator] = 'some task creator'
        queuer = clazz.new(configuration)

        expect(queuer.instance_variable_get(:@task_creator)).to eq('some task creator')
      end

      it 'will complain if not provided a queue from which to receive requests' do
        configuration.delete(:suite_request_queue)

        expect { clazz.new(configuration) }.to raise_error(ArgumentError, /must have/i)
      end

      it 'will complain if not provided an exchange to which it will post messages' do
        configuration.delete(:output_exchange)

        expect { clazz.new(configuration) }.to raise_error(ArgumentError, /must have/i)
      end

      it 'should be listening to its queue' do
        expect(mock_publisher).to have_received(:subscribe_with).with(queuer, anything)
      end

    end


    describe 'request validation' do

      it 'can validate its requests' do
        expect(queuer).to respond_to(:valid_request?)
      end

      it 'needs a request to validate' do
        expect(queuer.method(:valid_request?).arity).to eq(1)
      end

      [:name, :dependencies].each do |required_key|
        it "deems a request invalid if the request doesn't have the '#{required_key}' key" do
          request = {
              name: "Test Run 1",
              dependencies: ["resource_1","resource_2"]
          }

          request.delete(required_key)
          request = request.to_json

          expect(queuer.valid_request?(request)).to be false
        end
      end

      it 'deems a request invalid if it is not given at least one way to determine relevant tests' do
        bad_request = {
            name: "Test Run 1",
            dependencies: ["resource_1","resource_2"]
        }

        expect(queuer.valid_request?(bad_request.to_json)).to be false

        good_request = bad_request.dup
        good_request[:tests] = ['foo']
        expect(queuer.valid_request?(good_request.to_json)).to be true

        good_request = bad_request.dup
        good_request[:directories] = ['foo']
        expect(queuer.valid_request?(good_request.to_json)).to be true

        good_request = bad_request.dup
        good_request[:test_directory] = 'foo'
        expect(queuer.valid_request?(good_request.to_json)).to be true
      end

      it 'deems a request invalid if given a non-string test directory' do
        test_request[:test_directory] = ['an array']

        expect(queuer.valid_request?(test_request.to_json)).to be false

        test_request[:test_directory] = 'a string'

        expect(queuer.valid_request?(test_request.to_json)).to be true
      end

      it 'deems a request invalid if given a non-string root location' do
        test_request[:root_location] = ['an array']

        expect(queuer.valid_request?(test_request.to_json)).to be false

        test_request[:root_location] = 'a string'

        expect(queuer.valid_request?(test_request.to_json)).to be true
      end

      it 'deems a request invalid if given a non-array test collection' do
        test_request[:tests] = 'a string'

        expect(queuer.valid_request?(test_request.to_json)).to be false

        test_request[:tests] = ['an array']

        expect(queuer.valid_request?(test_request.to_json)).to be true
      end

      it 'deems a request invalid if given a non-array directory collection' do
        test_request[:directories] = 'a string'

        expect(queuer.valid_request?(test_request.to_json)).to be false

        test_request[:directories] = ['an array']

        expect(queuer.valid_request?(test_request.to_json)).to be true
      end

      it 'logs when it receives a valid request' do
        configuration[:suite_request_queue] = fake_publisher
        clazz.new(configuration)

        fake_publisher.call(create_mock_delivery_info, @mock_properties, test_request.to_json)

        expect(mock_logger).to have_received(:info).with(/request received/)
      end

    end

    describe 'bad request handling' do

      it 'can gracefully handle bad JSON' do
        configuration[:suite_request_queue] = fake_publisher
        clazz.new(configuration)
        bad_request = 'a very bad request'

        expect { fake_publisher.call(create_mock_delivery_info, @mock_properties, bad_request.to_json) }.to_not raise_error
      end

      it 'logs when it receives an invalid request' do
        configuration[:suite_request_queue] = fake_publisher
        clazz.new(configuration)
        bad_request = 'a very bad request'

        fake_publisher.call(create_mock_delivery_info, @mock_properties, bad_request.to_json)

        expect(mock_logger).to have_received(:error).with(/invalid.*request.*#{bad_request}/i)
      end

    end

    describe 'test finding' do

      it 'delegates test finding to its provided test finder' do
        test_request[:root_location] = @default_file_directory
        test_request[:directories] = ['some', 'directories']
        configuration[:suite_request_queue] = fake_publisher
        configuration[:test_finder] = mock_test_finder
        queuer = clazz.new(configuration)

        fake_publisher.call(create_mock_delivery_info, mock_properties, test_request.to_json)

        expect(mock_test_finder).to have_received(:find_test_cases)
      end

      it 'provides to its test finder a root location, a collection of directories in which to find tests, and a set of filters' do
        test_request[:directories] = ['some', 'directories']
        configuration[:suite_request_queue] = fake_publisher
        configuration[:test_finder] = mock_test_finder
        queuer = clazz.new(configuration)

        fake_publisher.call(create_mock_delivery_info, create_mock_properties, test_request.to_json)

        expect(mock_test_finder).to have_received(:find_test_cases).with(kind_of(String), kind_of(Array), kind_of(Hash))
      end

      it 'uses the root location given in the request as the root location provided to its test finder' do
        test_request[:directories] = ['some', 'directories']
        test_request[:root_location] = 'some root location'
        configuration[:suite_request_queue] = fake_publisher
        configuration[:test_finder] = mock_test_finder
        queuer = clazz.new(configuration)

        fake_publisher.call(create_mock_delivery_info, create_mock_properties, test_request.to_json)

        expect(mock_test_finder).to have_received(:find_test_cases).with('some root location', anything(), anything())
      end

      it 'uses the directories given in the request as the directories provided to its test finder' do
        test_request[:directories] = ['some', 'directories']
        configuration[:suite_request_queue] = fake_publisher
        configuration[:test_finder] = mock_test_finder
        queuer = clazz.new(configuration)

        fake_publisher.call(create_mock_delivery_info, create_mock_properties, test_request.to_json)

        expect(mock_test_finder).to have_received(:find_test_cases).with(anything(), ['some', 'directories'], anything())
      end

      it 'uses the filters given in the request as the filters provided to its test finder' do
        test_request[:tag_exclusions] = '@foo'
        test_request[:tag_inclusions] = '/bar/'
        test_request[:path_exclusions] = ['baz']
        test_request[:path_inclusions] = ['/buzz/']
        configuration[:suite_request_queue] = fake_publisher
        configuration[:test_finder] = mock_test_finder
        queuer = clazz.new(configuration)

        fake_publisher.call(create_mock_delivery_info, create_mock_properties, test_request.to_json)

        expect(mock_test_finder).to have_received(:find_test_cases).with(anything(), anything(), {excluded_tags: '@foo', included_tags: '/bar/', excluded_paths: ['baz'], included_paths: ['/buzz/']})
      end

      it 'does not search for tests if no directories are given in the request' do
        test_request.delete(:directories)
        configuration[:suite_request_queue] = fake_publisher
        configuration[:test_finder] = mock_test_finder
        queuer = clazz.new(configuration)

        fake_publisher.call(create_mock_delivery_info, create_mock_properties, test_request.to_json)

        expect(mock_test_finder).to_not have_received(:find_test_cases)
      end
    end

    describe 'task creation' do

      it 'delegates task creation to its provided task creator' do
        configuration[:suite_request_queue] = fake_publisher
        configuration[:task_creator] = mock_task_creator
        queuer = clazz.new(configuration)

        fake_publisher.call(create_mock_delivery_info, create_mock_properties, test_request.to_json)

        expect(mock_task_creator).to have_received(:create_tasks_for)
      end

      it 'provides to its task creator a collection of tests for which tasks are needed and other request data' do
        configuration[:suite_request_queue] = fake_publisher
        configuration[:task_creator] = mock_task_creator
        queuer = clazz.new(configuration)

        fake_publisher.call(create_mock_delivery_info, create_mock_properties, test_request.to_json)

        expect(mock_task_creator).to have_received(:create_tasks_for).with(kind_of(Hash), kind_of(Array))
      end

      it 'uses the given request data the request data provided to its test finder' do
        configuration[:suite_request_queue] = fake_publisher
        configuration[:task_creator] = mock_task_creator
        queuer = clazz.new(configuration)

        fake_publisher.call(create_mock_delivery_info, create_mock_properties, test_request.to_json)

        # May decide to send less information later but for now it is easiest to simply send everything along
        expect(mock_task_creator).to have_received(:create_tasks_for).with(hash_including(test_request), anything())
      end

      it 'includes explicit tests in the test collection provided to its task creator' do
        test_request[:tests] = ['some', 'tests']
        configuration[:suite_request_queue] = fake_publisher
        configuration[:task_creator] = mock_task_creator
        queuer = clazz.new(configuration)

        fake_publisher.call(create_mock_delivery_info, create_mock_properties, test_request.to_json)

        expect(mock_task_creator).to have_received(:create_tasks_for).with(anything(), array_including(test_request[:tests]))
      end

      it 'tests found in the provided directories are included in the test collection provided to its task creator' do
        test_finder = create_mock_test_finder
        allow(test_finder).to receive(:find_test_cases).and_return(['test_1', 'test_2'])
        test_request[:directories] = ['some_directory']
        configuration[:suite_request_queue] = fake_publisher
        configuration[:task_creator] = mock_task_creator
        configuration[:test_finder] = test_finder
        queuer = clazz.new(configuration)

        fake_publisher.call(create_mock_delivery_info, create_mock_properties, test_request.to_json)

        expect(mock_task_creator).to have_received(:create_tasks_for).with(anything(), array_including(['test_1', 'test_2']))
      end

    end

  end
end
