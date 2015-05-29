class NoDefaultDoneValueForScenarios < ActiveRecord::Migration
  def self.up
    change_column :scenarios, :done, :boolean
  end

  def self.down
    change_column :scenarios, :done, :boolean, default: false, null: false
  end
end
