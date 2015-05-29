class AddSuiteGuidOnScenario < ActiveRecord::Migration
  def self.up
    add_column :scenarios, :suite_guid, :string, null: false
  end

  def self.down
    remove_column :scenarios, :suite_guid
  end
end
