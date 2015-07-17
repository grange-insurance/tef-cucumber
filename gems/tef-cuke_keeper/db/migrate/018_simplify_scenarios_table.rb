class SimplifyScenariosTable < ActiveRecord::Migration
  def self.up
    remove_column :scenarios, :filename
    add_column :scenarios, :line_number, :integer, null: true
  end

  def self.down
    add_column :scenarios, :filename, :string, null: false
    remove_column :scenarios, :line_number
  end
end
