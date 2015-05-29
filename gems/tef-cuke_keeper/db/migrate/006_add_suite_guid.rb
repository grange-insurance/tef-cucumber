class AddSuiteGuid < ActiveRecord::Migration
  def self.up
    add_column :features, :suite_guid, :string, null: true
  end

  def self.down
    remove_column :features, :suite_guid
  end
end
