require 'simplecov'
SimpleCov.command_name 'tef-queuebert-cucumber'

require 'cucumber/rspec/doubles'
require 'bunny'
require 'open3'
# Used for #wait_for
require 'rspec/wait'
include RSpec::Wait

require 'tef/queuebert'

# Common testing code
require 'tef/development'
World(TEF::Development)

require 'tef/development/testing/fakes'
World(TEF::Development::Testing::Fakes)
require 'tef/development/testing/mocks'
World(TEF::Development::Testing::Mocks)


ENV['TEF_ENV'] ||= 'dev'
ENV['TEF_AMQP_URL_DEV'] ||= 'amqp://localhost:5672'


# todo - move hooks out to another file
Before do
  begin
    @tef_env = ENV['TEF_ENV'].downcase
    @bunny_url = ENV["TEF_AMQP_URL_#{@tef_env}"]


    @default_file_directory = "#{File.dirname(__FILE__)}/../temp_files"

    @base_request = {
        'name' => 'Test request',
        'dependencies' => ["foo","bar"],
    }


    @bunny_connection = Bunny.new(@bunny_url)
    @bunny_connection.start
    @bunny_channel = @bunny_connection.create_channel
  rescue Exception => e
    puts "caught before exception: #{e.message}"
    puts "trace: #{e.backtrace}"
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

# Create a sandbox for test files
Before('~@unit') do
  begin
    FileUtils.mkdir(@default_file_directory)
  rescue => e
    puts "Exceptions caught in before hook"
    puts e.message
  end
end

# Delete the file sandbox
After('~@unit') do
  FileUtils.remove_dir(@default_file_directory, true)
end


# todo - move these helper methods out to another file

def process_path(path)
  path.sub('path/to', @default_file_directory)
end

def process_filter(filter)
  filter = process_path(filter)
  filter =~ /^\/.+\/$/ ? Regexp.new(filter.slice(1..-2)) : filter
end

def messages_from_queue(queue_name)
  queue = get_queue(queue_name)

  messages = []
  queue.message_count.times do
    messages << queue.pop
  end

  # Extracting the payload portion of the messages
  messages.map { |task|
    {
        delivery_info: task[0],
        meta_data: task[1],
        body: JSON.parse(task[2])
    }
  }.flatten
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
