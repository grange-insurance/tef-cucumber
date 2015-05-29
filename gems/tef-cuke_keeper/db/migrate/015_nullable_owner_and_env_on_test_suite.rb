class NullableOwnerAndEnvOnTestSuite < ActiveRecord::Migration
  def self.up
    change_column :test_suites, :owner, :string, null: true
    change_column :test_suites, :env, :string, null: true
  end

  def self.down
    change_column :test_suites, :owner, :string, null: false
    change_column :test_suites, :env, :string, null: false
  end
end
