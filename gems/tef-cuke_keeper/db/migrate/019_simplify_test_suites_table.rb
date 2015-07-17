class SimplifyTestSuitesTable < ActiveRecord::Migration
  def self.up
    remove_column :test_suites, :env
    remove_column :test_suites, :owner
  end

  def self.down
    add_column :test_suites, :env, :string, null: true
    add_column :test_suites, :owner, :string, null: false
  end
end
