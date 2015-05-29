#!/bin/env ruby

####################################################################################
#
#  This is a reference implementation of a TEF queuebert executable.
#  Since all dependencies are injected, something has to wire them together
#  this is one way that thing can be put together.
#

require_relative '../lib/searching'
require_relative '../lib/tasking'
require_relative '../lib/queuer'
#require_relative '../lib/task_queue'
#require_relative '../lib/worker_collective'
#require_relative '../lib/resource_manager'
require 'bunny'
#require 'logger'

EXIT_CODE_NO_URL = 1
EXIT_CODE_FAILED_RABBIT = 2

def main
  puts 'Spinning up Queuebert...'
  channel = connect_rabbit
  queue_prefix = "tef.#{tef_env}"
  puts 'Creating logger...'
  logger = Logger.new(STDOUT)
  logger.info('Creating queues')
  request_queue = channel.queue("#{queue_prefix}.queuebert.request", :durable => true)
  manager_queue = channel.queue("#{queue_prefix}.task_queue.control", :durable => true)

  logger.info('Creating task queuer...')
  task_queue = TEF::Queuebert::Queuer.new(request_queue, manager_queue)
  begin
    #loop do
      # Nothing
    #end
  rescue Interrupt => _
    puts 'Closing Queuebert connection...'

    @connection.stop
    exit(0)
  end
end


def bunny_env_name
  "TEF_AMQP_URL_#{tef_env.upcase}"
end

def tef_env
  ENV['TEF_ENV'] != nil ? ENV['TEF_ENV'].downcase : 'dev'
end

#def tef_config
#  ENV['TEF_CONFIG'] != nil ? ENV['TEF_CONFIG'] : "#{File.dirname(__FILE__)}/../config"
#end

def connect_rabbit
  puts "Connecting to RabbitMQ..."
  bunny_url = ENV[bunny_env_name]
  puts "bunny url found: #{bunny_url}"
  if bunny_url.nil?
    puts "Missing environment variable #{bunny_env_name}.  Cannot connect to RabbitMQ"
    exit(EXIT_CODE_NO_URL)
  end

  begin
    @connection = Bunny.new(bunny_url)
    @connection.start
    channel = @connection.create_channel
  rescue => ex
    puts "Failed to connect to RabbitMQ\n#{ex.message}\n#{ex.backtrace}"
    exit(EXIT_CODE_FAILED_RABBIT)
  end

  channel
end


main
