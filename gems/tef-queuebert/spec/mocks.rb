module TEF
  module TestingMocks

    def create_mock_test_finder
      mock_thing = double('mock test finder')
      allow(mock_thing).to receive(:find_test_cases).and_return([])

      mock_thing
    end

    def create_mock_task_creator
      mock_thing = double('mock task creator')
      allow(mock_thing).to receive(:create_tasks_for)

      mock_thing
    end

  end
end
