require 'bunny'
require 'logger'

require 'tef/core'
require 'tef/queuebert/queuer'
require 'tef/queuebert/searching'
require 'tef/queuebert/tasking'


module TEF
  module Queuebert
    class Queuebert < TEF::TefComponent

      attr_reader :logger, :suite_request_queue_name, :manager_queue_name, :keeper_queue_name

      EXIT_CODE_FAILED_QUEUE = 3


      def initialize(options = {})
        super(options)

        @queue_prefix = options.fetch(:queue_prefix, "tef.#{tef_env}")
        @suite_request_queue = options.fetch(:suite_request_queue, "#{@queue_prefix}.queuebert.request")
        @manager_queue = options.fetch(:manager_queue, "#{@queue_prefix}.task_queue.control")
        @keeper_queue = options.fetch(:keeper_queue, "#{@queue_prefix}.keeper.cucumber")

        @logger.info('Queuebert created.')
      end

      def start
        super

        create_message_queues
        create_queuer

        @logger.info('Queuebert started.')
      end


      private


      def create_message_queues
        @logger.debug('creating control queues')
        begin
          channel = @connection.create_channel

          @suite_request_queue = channel.queue(@suite_request_queue, :durable => true) if @suite_request_queue.is_a?(String)
          @suite_request_queue_name = @suite_request_queue.name
          @logger.info "Suite request queue: #{@suite_request_queue_name} (channel #{channel.id})"

          @manager_queue = channel.queue(@manager_queue, :durable => true) if @manager_queue.is_a?(String)
          @manager_queue_name = @manager_queue.name
          @logger.info "Manager queue: #{@manager_queue_name} (channel #{channel.id})"

          @keeper_queue = channel.queue(@keeper_queue, :durable => true) if @keeper_queue.is_a?(String)
          @keeper_queue_name = @keeper_queue.name
          @logger.info "Keeper queue: #{@keeper_queue_name} (channel #{channel.id})"
        rescue => ex
          @logger.error("Failed to create control queues.  #{ex.message}")
          puts "Failed to create control queues.  #{ex.message}"
          exit(EXIT_CODE_FAILED_QUEUE)
        end
      end

      def create_queuer
        @logger.debug('creating queuer')
        queuer_options = {suite_request_queue: @suite_request_queue,
                          manager_queue: @manager_queue,
                          keeper_queue: @keeper_queue,
                          logger: @logger}

        #todo - dependency inject this
        @queuer = TEF::Queuebert::Queuer.new(queuer_options)
      end

    end
  end
end
