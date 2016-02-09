require 'simplecov'
SimpleCov.command_name 'tef-cucumber-cucumber'

require 'open3'
require 'bunny'

# Used for #wait_for
require 'rspec/wait'
include RSpec::Wait

RSpec.configure do |config|
  config.wait_timeout = 30
end

# Common testing code
require 'tef/development'
World(TEF::Development)

require 'tef/development/testing/database'
# Forcing a config file to be present so that no one accidentally ruins an important
# database just because they forgot to change an environmental variable
db_config = File.open("#{File.dirname(__FILE__)}/../../database_dev.yml") { |file| YAML.load(file) }
TEF::Development::Testing.connect_to_test_db(db_config: db_config)

require 'database_cleaner'
DatabaseCleaner.strategy = :truncation, {only: %w(keeper_dev_features keeper_dev_scenarios keeper_dev_test_suites tef_dev_tasks tef_dev_task_resources)}
DatabaseCleaner.start
DatabaseCleaner.clean


require 'tef/cucumber'

# Still need to call the CukeKeeper's initialization method in order to set the table_prefixes correctly
TEF::CukeKeeper::init_db


ENV['TEF_ENV'] ||= 'dev'
ENV['TEF_AMQP_URL_DEV'] ||= 'amqp://localhost:5672'


Before do
  begin
    @tef_env = ENV['TEF_ENV'].downcase
    @bunny_url = ENV["TEF_AMQP_URL_#{@tef_env}"]


    @base_request = {
        'name' => 'TEF test cucumber suite request',
        'dependencies' => '',
    }

    @test_search_root = "#{File.dirname(__FILE__)}/../../testing"

    @bunny_connection = Bunny.new(@bunny_url)
    @bunny_connection.start
    @bunny_channel = @bunny_connection.create_channel
  rescue => e
    puts "caught before exception: #{e.message}"
    puts "backtrace: #{e.backtrace}"
    raise e
  end
end


# Put Rabbit in a clean state between tests
Before('~@unit') do
  begin
    delete_all_message_queues
    delete_test_message_exchanges
  rescue => e
    puts "Exceptions caught in before hook"
    puts e.message
  end
end

After do
  kill_existing_tef_processes
  DatabaseCleaner.clean
end


def delete_all_message_queues
  stdout, stderr, status = Open3.capture3('rabbitmqctl list_queues name')
  queue_list = stdout.split("\n").slice(1..-2)

  queue_list.each { |queue| delete_queue(queue) }
end

def delete_test_message_exchanges
  stdout, stderr, status = Open3.capture3('rabbitmqctl list_exchanges name')
  exchange_list = stdout.split("\n").slice(1..-1)

  # Don't want to delete Rabbit's own exchanges
  exchange_list.delete('')
  exchange_list.delete_if { |name| name =~ /amq/ }

  exchange_list.each { |exchange| delete_exchange(exchange) }
end
