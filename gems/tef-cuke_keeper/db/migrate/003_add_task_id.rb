class AddTaskId < ActiveRecord::Migration
  def self.up
    add_column :scenarios, :task_id, :string, null: false
  end

  def self.down
    remove_column :scenarios, :task_id
  end
end
