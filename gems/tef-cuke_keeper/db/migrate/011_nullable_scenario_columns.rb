class NullableScenarioColumns < ActiveRecord::Migration
  def self.up
    change_column :scenarios, :feature_id, :integer, null: true
    change_column :scenarios, :status, :string, null: true
    change_column :scenarios, :name, :string, null: true
    change_column :scenarios, :filename, :string, null: true
  end

  def self.down
    change_column :scenarios, :feature_id, :integer, null: false
    change_column :scenarios, :status, :string, null: false
    change_column :scenarios, :name, :string, null: false
    change_column :scenarios, :filename, :string, null: false
  end
end
