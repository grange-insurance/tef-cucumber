require 'active_record'

module TEF
  module CukeKeeper
    module Models
      class Scenario < ActiveRecord::Base
        belongs_to :feature, autosave: true
      end
    end
  end
end
