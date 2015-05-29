# Create the initial tables
class AddStatus < ActiveRecord::Migration
  def self.up
    change_table :scenarios do |t|
      t.column :status, :string,   null: false, default: 'pass'
    end
  end

  def self.down
  end
end
