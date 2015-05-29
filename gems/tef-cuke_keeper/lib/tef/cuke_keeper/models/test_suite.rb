require 'active_record'

module TEF
  module CukeKeeper
    module Models
      class TestSuite  < ActiveRecord::Base
        has_many :features
      end
    end
  end
end
