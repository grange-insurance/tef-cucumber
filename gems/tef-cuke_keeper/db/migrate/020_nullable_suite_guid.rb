class NullableSuiteGuid < ActiveRecord::Migration
  def self.up
    change_column :features, :suite_guid, :string, null: true
  end

  def self.down
    change_column :features, :suite_guid, :string, null: false
  end
end
