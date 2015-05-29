require 'tef/worker'
require 'cuke_runner'

module TEF
  module Worker
    class CukeWorker < BaseWorker
      def initialize(options)
        # Have to take care of the logger now (instead of letting the super call handle it) so that
        # it can be given to the runner when it is initialized.
        @logger = options[:logger] = options.fetch(:logger, Logger.new($stdout))

        options[:worker_type] = options.fetch(:worker_type, 'cucumber')
        options[:runner] = options.fetch(:runner, CukeRunner::Runner.new(logger: @logger))

        super(options)
      end

    end
  end
end
