class AddDoneStatus < ActiveRecord::Migration
  def self.up
    add_column :scenarios, :done, :boolean, default: false, null: false
  end

  def self.down
    remove_column :scenarios, :done
  end
end
