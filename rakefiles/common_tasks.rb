require 'tef/development/common_tasks'


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
