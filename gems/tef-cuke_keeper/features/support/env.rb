require 'simplecov'
SimpleCov.command_name 'tef-cuke_keeper-cucumber'

require 'cucumber/rspec/doubles'

# Common testing code
require 'tef/development/testing/mocks'
World(TEF::Development::Testing::Mocks)


require 'tef/development/testing/database'
TEF::Development::Testing.connect_to_test_db

require 'database_cleaner'
DatabaseCleaner.strategy = :truncation, {only: %w(keeper_dev_features keeper_dev_scenarios keeper_dev_test_suites)}
DatabaseCleaner.start
DatabaseCleaner.clean


require 'tef/cuke_keeper'
TEF::CukeKeeper.init_db


Before do
  DatabaseCleaner.clean
end
