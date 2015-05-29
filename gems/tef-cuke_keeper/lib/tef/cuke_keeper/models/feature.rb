require 'active_record'

module TEF
  module CukeKeeper
    module Models
      class Feature < ActiveRecord::Base
        belongs_to :test_suite, autosave: true
        has_many :scenarios
      end
    end
  end
end
