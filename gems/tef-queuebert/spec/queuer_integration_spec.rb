require 'spec_helper'


describe 'Queuer, Integration' do

  clazz = TEF::Queuebert::Queuer


  before(:each) do
    FileUtils.mkpath("#{@default_file_directory}/test_directory_1")
    FileUtils.mkpath("#{@default_file_directory}/test_directory_2")

    test_file = "#{@default_file_directory}/test_directory_1/a_test.feature"
    file_text = "Feature: A test feature

                   Scenario: Test scenario
                     * some step"
    File.open(test_file, 'w') { |file| file.write(file_text) }

    test_file = "#{@default_file_directory}/test_directory_2/another_test.feature"
    file_text = "Feature: Another test feature

                   Scenario: Test scenario
                     * some step"
    File.open(test_file, 'w') { |file| file.write(file_text) }


    @test_request = {
        'name' => 'Test request',
        'dependencies' => 'foo|bar',
        'root_location' => 'root location foo',
        'tests' => ['some', 'tests']
    }

    @mock_logger = create_mock_logger
    @mock_test_finder = create_mock_test_finder
    @mock_task_creator = create_mock_task_creator
    @mock_properties = create_mock_properties
    @mock_exchange = create_mock_exchange
    @mock_channel = create_mock_channel(@mock_exchange)
    @mock_publisher = create_mock_queue(@mock_channel)

    @mock_task_creator = double('task_creator')
    allow(@mock_task_creator).to receive(:create_tasks_for).and_return([])

    @fake_publisher = create_fake_publisher(@mock_channel)

    @options = {suite_request_queue: @mock_publisher, manager_queue: create_mock_queue, keeper_queue: create_mock_queue, task_creator: @mock_task_creator}
  end

  it_should_behave_like 'a logged component, integration level' do
    let(:clazz) { clazz }
    let(:configuration) { @options }
  end


  describe 'task creation' do

    it "defaults to Queuebert's tasking module if a task creator is not provided" do
      @options.delete(:task_creator)
      queuer = clazz.new(@options)

      expect(queuer.instance_variable_get(:@task_creator)).to eq(TEF::Queuebert::Tasking)
    end

  end

  describe 'test finding' do

    it "defaults to Queuebert's searching module if a test finder is not provided" do
      @options.delete(:test_finder)
      queuer = clazz.new(@options)

      expect(queuer.instance_variable_get(:@test_finder)).to eq(TEF::Queuebert::Searching)
    end

    it 'uses the configured root location as the root location provided to its test finder if one is not provided in the request' do
      root_var = 'TEF_QUEUEBERT_SEARCH_ROOT'
      old_root = ENV[root_var]

      begin
        @test_request.delete('root_location')
        ENV[root_var] = 'configured root location'
        @test_request['directories'] = ['some directory']
        @options[:suite_request_queue] = @fake_publisher
        @options[:test_finder] = @mock_test_finder
        queuer = clazz.new(@options)

        @fake_publisher.call(create_mock_delivery_info, create_mock_properties, @test_request.to_json)

        expect(@mock_test_finder).to have_received(:find_test_cases).with('configured root location', anything(), anything())
      ensure
        # Making sure that our changes don't escape a test and ruin the rest of the suite
        ENV[root_var] = old_root
      end
    end

  end

  it 'only treats the given test directory as an explicit directory when no other sources are given' do
    @options[:suite_request_queue] = @fake_publisher
    @options[:task_creator] = @mock_task_creator
    queuer = clazz.new(@options) # Not using the queuer, just linking it up with the publisher


    request = @test_request.dup
    root_location = @default_file_directory.match(/^(.:)/)[1]
    test_directory = @default_file_directory.match(/^.:.(.*)$/)[1]
    request['root_location'] = root_location
    request['test_directory'] = test_directory


    # Tests present
    request.delete('directories')
    request['tests'] = ['test_directory_1/a_test.feature:1']
    @fake_publisher.call(create_mock_delivery_info, @mock_properties, request.to_json)

    expect(@mock_task_creator).to have_received(:create_tasks_for).with(anything(), ["#{test_directory}/test_directory_1/a_test.feature:1"]).at_least(:once)

    # Directories present
    request.delete('tests')
    request['directories'] = ['test_directory_1']
    @fake_publisher.call(create_mock_delivery_info, @mock_properties, request.to_json)

    expect(@mock_task_creator).to have_received(:create_tasks_for).with(anything(), ["#{test_directory}/test_directory_1/a_test.feature:3"]).at_least(:once)

    # Test directory only
    request.delete('tests')
    request.delete('directories')
    @fake_publisher.call(create_mock_delivery_info, @mock_properties, request.to_json)

    expect(@mock_task_creator).to have_received(:create_tasks_for).with(anything(), ["#{test_directory}/test_directory_1/a_test.feature:3",
                                                                                     "#{test_directory}/test_directory_2/another_test.feature:3"]).at_least(:once)
  end

  it 'fully expands file paths when determining test path uniqueness' do
    @options[:suite_request_queue] = @fake_publisher
    @options[:task_creator] = @mock_task_creator
    @options[:test_finder] = @mock_test_finder
    queuer = clazz.new(@options) # Not using the queuer, just linking it up with the publisher


    request = @test_request.dup
    root_location = @default_file_directory
    test_directory = 'test_directory_1'
    request['root_location'] = @default_file_directory
    request['test_directory'] = test_directory


    # Several test paths that all equate to the same test
    request.delete('directories')
    request['directories'] = ['.']
    request['tests'] = ['a_test.feature:3', "../#{test_directory}/a_test.feature:3", 'a_test.feature:3']
    @fake_publisher.call(create_mock_delivery_info, @mock_properties, request.to_json)

    expect(@mock_task_creator).to have_received(:create_tasks_for).with(anything(), ["#{test_directory}/a_test.feature:3"]).at_least(:once)
  end

  # todo - This is a more indirect way of testing the root location configuration. Which one to use?
  it 'uses the configured root location if one is not provided in the request' do
    root_var = 'TEF_QUEUEBERT_SEARCH_ROOT'
    old_root = ENV[root_var]

    @options[:suite_request_queue] = @fake_publisher
    @options[:task_creator] = @mock_task_creator
    queuer = clazz.new(@options) # Not using the queuer, just linking it up with the publisher

    @test_request['tests'] = ['test_directory_1/a_test.feature:1']
    root_location = @default_file_directory

    begin
      @test_request.delete('root_location')
      ENV[root_var] = root_location

      @fake_publisher.call(create_mock_delivery_info, @mock_properties, @test_request.to_json)

      expect(@mock_task_creator).to have_received(:create_tasks_for).with(anything(), ["test_directory_1/a_test.feature:1"]).at_least(:once)
    ensure
      # Making sure that our changes don't escape a test and ruin the rest of the suite
      ENV[root_var] = old_root
    end

  end

  it "logs when it can't determine a root location" do
    root_var = 'TEF_QUEUEBERT_SEARCH_ROOT'
    old_root = ENV[root_var]

    @options[:suite_request_queue] = @fake_publisher
    @options[:task_creator] = @mock_task_creator
    @options[:logger] = @mock_logger
    queuer = clazz.new(@options) # Not using the queuer, just linking it up with the publisher

    begin
      @test_request['tests'] = ['test_directory_1/a_test.feature:1']
      @test_request.delete('root_location')
      ENV[root_var] = nil

      begin
        @fake_publisher.call(create_mock_delivery_info, create_mock_properties, @test_request.to_json)
      rescue ArgumentError
      end

      expect(@mock_logger).to have_received(:error).with(/can't determine root/i)
    ensure
      # Making sure that our changes don't escape a test and ruin the rest of the suite
      ENV[root_var] = old_root
    end
  end

  it "acknowledges the messages that it handles, even if a root location can't be determined" do
    root_var = 'TEF_QUEUEBERT_SEARCH_ROOT'
    old_root = ENV[root_var]
    delivery_info = create_mock_delivery_info
    @options[:suite_request_queue] = @fake_publisher

    clazz.new(@options) # Not using the queuer, just linking it up with the publisher

    begin
      @test_request.delete('root_location')
      ENV[root_var] = nil

      begin
        @fake_publisher.call(delivery_info, create_mock_properties, @test_request.to_json)
      rescue ArgumentError
      end

      expect(@mock_channel).to have_received(:acknowledge).with(delivery_info.delivery_tag, false)
    ensure
      # Making sure that our changes don't escape a test and ruin the rest of the suite
      ENV[root_var] = old_root
    end

  end

  describe 'bad message handling' do

    it 'acknowledges the messages that it handles, even if errors occur while handling them' do
      delivery_info = create_mock_delivery_info
      @options[:suite_request_queue] = @fake_publisher
      @test_request['directories'] =['not a real directory']


      clazz.new(@options) # Not using the queuer, just linking it up with the publisher

      begin
        @fake_publisher.call(delivery_info, create_mock_properties, @test_request.to_json)
      rescue ArgumentError
      end


      expect(@mock_channel).to have_received(:acknowledge).with(delivery_info.delivery_tag, false)
    end

    it 'logs when an error occurs while handling a message' do
      delivery_info = create_mock_delivery_info
      @options[:suite_request_queue] = @fake_publisher
      @options[:logger] = @mock_logger
      @test_request['directories'] = ['not a real directory']


      clazz.new(@options) # Not using the queuer, just linking it up with the publisher

      begin
        @fake_publisher.call(delivery_info, create_mock_properties, @test_request.to_json)
      rescue ArgumentError
      end

      expect(@mock_logger).to have_received(:error).with(/there was a problem/i)
    end

  end

  describe 'task queuing' do

    it 'it logs the tasks that it queues' do
      delivery_info = create_mock_delivery_info
      @options[:suite_request_queue] = @fake_publisher
      @options[:logger] = @mock_logger
      allow(@mock_task_creator).to receive(:create_tasks_for).and_return([{task_1: 'foo'}, {task_2: 'bar'}])

      clazz.new(@options) # Not using the queuer, just linking it up with the publisher

      @fake_publisher.call(delivery_info, create_mock_properties, @test_request.to_json)

      expect(@mock_logger).to have_received(:debug).with('Forwarding 2 tasks...')
      expect(@mock_logger).to have_received(:debug).with('forwarding task: {"task_1":"foo"}')
      expect(@mock_logger).to have_received(:debug).with('forwarding task: {"task_2":"bar"}')
    end

  end

end
