require 'simplecov'
SimpleCov.command_name 'tef-queuebert-cucumber'

require 'cucumber/rspec/doubles'
require 'bunny'
require 'open3'
# Used for #wait_for
require 'rspec/wait'
include RSpec::Wait

require 'tef/queuebert'

require 'tef/development/testing/fakes'
World(TEF::Development::Testing::Fakes)
require 'tef/development/testing/mocks'
World(TEF::Development::Testing::Mocks)


ENV['TEF_ENV'] ||= 'dev'
ENV['TEF_AMQP_URL_DEV'] ||= 'amqp://localhost:5672'


Before do
  begin
    @tef_env = ENV['TEF_ENV'].downcase
    @bunny_url = ENV["TEF_AMQP_URL_#{@tef_env}"]


    @default_file_directory = "#{File.dirname(__FILE__)}/../temp_files"

    @base_request = {
        'name' => 'Test request',
        'dependencies' => 'foo|bar',
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

Before('~@unit') do
  begin
    stdout, stderr, status = Open3.capture3('rabbitmqctl list_queues name')
    queue_list = stdout.split("\n").slice(1..-2)

    queue_list.each { |queue| delete_queue(queue) }

    FileUtils.mkdir(@default_file_directory)
  rescue => e
    puts "Exceptions caught in before hook"
    puts e.message
  end
end

After('~@unit') do
  FileUtils.remove_dir(@default_file_directory, true)
end


def process_path(path)
  path.sub('path/to', @default_file_directory)
end

def process_filter(filter)
  filter = process_path(filter)
  filter =~ /^\/.+\/$/ ? Regexp.new(filter.slice(1..-2)) : filter
end

# This seems like something that Bunny should already have...
def get_queue(queue_name)
  @bunny_channel.queue(queue_name, passive: true)
end

def delete_queue(queue_name)
  @bunny_channel.queue_delete(queue_name)
end
