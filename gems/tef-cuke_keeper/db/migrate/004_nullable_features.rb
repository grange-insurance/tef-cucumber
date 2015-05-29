class NullableFeatures < ActiveRecord::Migration
  def self.up
    change_column :scenarios, :feature_id, :integer, null: true
  end

  def self.down
    change_column :scenarios, :feature_id, :integer, null: false
  end
end
