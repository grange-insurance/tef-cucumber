module BundleDaemon
  class BundleDaemonRabbit

    def initialize(ch)
      @ch = ch
      @sb = SmartBundler.new
    end

    def start(queue_name)
      @q = @ch.queue(queue_name)
      @x = @ch.default_exchange

      puts("Listening in: #{queue_name}")
      @q.subscribe(:block => true) do |delivery_info, properties, payload|
        begin
          r = @sb.bundle_install(payload)
        rescue
          r = false
        end


        puts " [.] Bundle install: #{payload} (#{r})"

        @x.publish(r.to_s, :routing_key => properties.reply_to, :correlation_id => properties.correlation_id)
      end
    end


  end
end
