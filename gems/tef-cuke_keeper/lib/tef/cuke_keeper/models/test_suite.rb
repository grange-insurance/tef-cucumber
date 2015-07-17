require 'active_record'

module TEF
  module CukeKeeper
    module Models
      class TestSuite  < ActiveRecord::Base
        has_many :features, foreign_key: 'suite_guid'
      end
    end
  end
end
