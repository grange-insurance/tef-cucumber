class RenameTaskId < ActiveRecord::Migration
  def self.up
    rename_column :scenarios, :task_id, :task_guid
  end

  def self.down
    rename_column :scenarios, :task_guid, :task_id
  end
end
