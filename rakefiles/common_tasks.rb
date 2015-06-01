module TEF
  module Cucumber
    def self.component_locations
      {
          'mdf' => 'gems/mdf',
          'cuke_runner' => 'gems/cuke_runner',
          'bundle_daemon' => 'gems/bundle_daemon',
          'tef-cuke_keeper' => 'gems/tef-cuke_keeper',
          'tef-queuebert' => 'gems/tef-queuebert',
          'tef-worker-cuke_worker' => 'gems/tef-worker-cuke_worker',
          'tef-cucumber' => 'gems/..'
      }
    end
  end
end

namespace 'tef' do

  task :set_environment do
    ENV['TEF_ENV'] ||= 'dev'
    ENV['TEF_AMQP_URL_DEV'] ||= 'amqp://localhost:5672'
    ENV['TEF_AMQP_USER_DEV'] ||= 'guest'
    ENV['TEF_AMQP_PASSWORD_DEV'] ||= 'guest'
  end

end
