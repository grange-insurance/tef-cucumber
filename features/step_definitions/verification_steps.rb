Then(/^results for the executed tests are stored by the keeper$/) do
  expected_test_cases = ["features/more_features/test_feature_2.feature:3",
                         "features/more_features/test_feature_2.feature:7",
                         "features/test_feature_1.feature:3"]

  # Keeper needs to be ready
  keeper_queue_name = "tef.#{@tef_env}.keeper.cucumber"
  wait_for { puts "Waiting for queue #{keeper_queue_name} to be available..."; @bunny_connection.queue_exists?(keeper_queue_name) }.to be true

  # And the results need time to be ready
  # RSpec::Wait::Handler.set_wait_timeout(180)
  wait(60).for { get_tests_for_suite(@test_suite_guid).count }.to eq(expected_test_cases.count)

  stored_test_cases = get_tests_for_suite(@test_suite_guid)
  stored_test_cases.collect! { |test_case| "#{test_case.feature.filename}:#{test_case.line_number}" }
  stored_test_cases.collect! { |test_case| test_case.gsub('\\', '/') }

  expect(stored_test_cases).to match_array(expected_test_cases)
end


def get_tests_for_suite(suite_guid)
  results = TEF::CukeKeeper::Models::Scenario.joins("INNER JOIN keeper_#{ENV['TEF_ENV'].downcase}_features ON keeper_#{ENV['TEF_ENV'].downcase}_features.id=keeper_#{ENV['TEF_ENV'].downcase}_scenarios.feature_id INNER JOIN keeper_#{ENV['TEF_ENV'].downcase}_test_suites ON keeper_#{ENV['TEF_ENV'].downcase}_features.suite_guid=keeper_#{ENV['TEF_ENV'].downcase}_test_suites.guid")
  results = results.where("keeper_#{ENV['TEF_ENV'].downcase}_test_suites.guid=#{suite_guid}")

  results
end
