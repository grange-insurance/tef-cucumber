require 'bunny'
require 'logger'

require 'tef/core'
require 'tef/queuebert/queuer'
require 'tef/queuebert/searching'
require 'tef/queuebert/tasking'


module TEF
  module Queuebert
    class Queuebert < Core::OuterComponent


      def initialize(options = {})
        super(options)

        @logger.info('Queuebert created.')
      end

      def start
        super

        create_queuer

        # Monkey patching a module so that it we can log inside of it
        CukeModeler::Parsing.set_logger(logger)

        @logger.info('Queuebert started.')
      end


      private


      def configure_self(options)
        super

        @name_prefix = options.fetch(:name_prefix, "tef.#{tef_env}")
        @in_queue = options.fetch(:in_queue, "#{@name_prefix}.queuebert.request")
        @output_exchange = options.fetch(:output_exchange, "#{@name_prefix}.queuebert_generated_messages")
      end

      def create_queuer
        @logger.debug('creating queuer')
        queuer_options = {in_queue: @in_queue,
                          output_exchange: @output_exchange,
                          logger: @logger}

        #todo - dependency inject this
        @queuer = TEF::Queuebert::Queuer.new(queuer_options)
      end

    end
  end
end
