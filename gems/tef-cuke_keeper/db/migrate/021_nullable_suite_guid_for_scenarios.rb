class NullableSuiteGuidForScenarios < ActiveRecord::Migration
  def self.up
    change_column :scenarios, :suite_guid, :string, null: true
  end

  def self.down
    change_column :scenarios, :suite_guid, :string, null: false
  end
end
