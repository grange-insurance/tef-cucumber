#!/usr/bin/env ruby
require 'yaml'
require 'socket'
require 'bundle_daemon'
require 'bunny'
require 'eventmachine'


module BundleDaemon



  tef_env = ENV['TEF_ENV'] != nil ? ENV['TEF_ENV'].downcase : 'dev'

  bunny_env_name = "TEF_AMQP_URL_#{tef_env.upcase}"
  bunny_env_user ="TEF_AMQP_USER_#{tef_env.upcase}"
  bunny_env_password = "TEF_AMQP_PASSWORD_#{tef_env.upcase}"
  bunny_url = ENV[bunny_env_name]
  bunny_username = ENV[bunny_env_user]
  bunny_password = ENV[bunny_env_password]

  unless bunny_url
    puts "No URL found, have you defined #{bunny_env_name}"
    exit 1
  end


  begin



    connection_options= {
        host: bunny_url.match(/\/\/(.*):\d+$/)[1],
        port: bunny_url.match(/:(\d+)$/)[1]
    }

    connection_options[:username] = bunny_username if bunny_username
    connection_options[:password] = bunny_password if bunny_password
    puts "connection options: #{connection_options}"

    # todo - Not sure why auto-reconnection still works (i.e. the relevant test passes). It
    # wasn't working without this before...
    #@connection = Bunny.new(host: host, port: port, recover_from_connection_close: true)

    # Todo - Not much way to check what options are used when connecting since we can't pass a mock in for this
    conn = Bunny.new(connection_options)

    conn.start

    ch = conn.create_channel

    server = BundleDaemonRabbit.new(ch)
    puts " [x] Awaiting RPC requests"
    server.start("bundle.#{Socket.gethostname}")
  rescue Interrupt => _
    ch.close
    conn.close

    exit(0)
  end
end
