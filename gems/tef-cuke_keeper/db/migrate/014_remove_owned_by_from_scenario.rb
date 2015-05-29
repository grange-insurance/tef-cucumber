class RemoveOwnedByFromScenario < ActiveRecord::Migration
  def self.up
    remove_column :scenarios, :owned_by
  end

  def self.down
    add_column :scenarios, :owned_by, :string, null: true
  end
end
