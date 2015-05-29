class NullableTestSuiteId < ActiveRecord::Migration
  def self.up
    change_column :features, :test_suite_id, :integer, null: true
  end

  def self.down
    change_column :features, :test_suite_id, :integer, null: false
  end
end
