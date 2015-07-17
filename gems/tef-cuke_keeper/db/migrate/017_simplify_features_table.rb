class SimplifyFeaturesTable < ActiveRecord::Migration
  def self.up
    remove_column :features, :owned_by
    remove_column :features, :test_suite_id
  end

  def self.down
    add_column :features, :owned_by, :string, null: true
    add_column :features, :test_suite_id, :integer, null: true
  end
end
