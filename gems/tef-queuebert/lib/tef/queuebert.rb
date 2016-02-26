require 'bunny'
require 'logger'

require 'tef/core'
require 'tef/queuebert/queuer'
require 'tef/queuebert/searching'
require 'tef/queuebert/tasking'


module TEF
  module Queuebert
    class Queuebert < Core::TefComponent

      attr_reader :logger, :suite_request_queue_name, :output_exchange_name

      EXIT_CODE_FAILED_QUEUE = 3


      def initialize(options = {})
        super(options)

        @name_prefix = options.fetch(:queue_prefix, "tef.#{tef_env}")
        @suite_request_queue = options.fetch(:suite_request_queue, "#{@name_prefix}.queuebert.request")
        @output_exchange = options.fetch(:output_exchange, "#{@name_prefix}.queuebert_generated_messages")

        @logger.info('Queuebert created.')
      end

      def start
        super

        create_message_destinations
        create_queuer

        # Monkey patching a module so that it we can log inside of it
        CukeModeler::Parsing.set_logger(logger)

        @logger.info('Queuebert started.')
      end


      private


      def create_message_destinations
        @logger.debug('creating message endpoints')
        begin
          channel = @connection.create_channel

          @suite_request_queue = channel.queue(@suite_request_queue, :durable => true) if @suite_request_queue.is_a?(String)
          @suite_request_queue_name = @suite_request_queue.name
          @logger.info "Suite request queue: #{@suite_request_queue_name} (channel #{channel.id})"

          # todo - test that the exchange created is a topical exchange
          @output_exchange = channel.topic(@output_exchange, :durable => true) if @output_exchange.is_a?(String)
          @output_exchange_name = @output_exchange.name
          @logger.info "Output exchange: #{@output_exchange_name} (channel #{channel.id})"
        rescue => ex
          @logger.error("Failed to create control queues.  #{ex.message}")
          puts "Failed to create control queues.  #{ex.message}"
          exit(EXIT_CODE_FAILED_QUEUE)
        end
      end

      def create_queuer
        @logger.debug('creating queuer')
        queuer_options = {suite_request_queue: @suite_request_queue,
                          output_exchange: @output_exchange,
                          logger: @logger}

        #todo - dependency inject this
        @queuer = TEF::Queuebert::Queuer.new(queuer_options)
      end

    end
  end
end
