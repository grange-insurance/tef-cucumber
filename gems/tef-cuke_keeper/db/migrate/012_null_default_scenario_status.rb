class NullDefaultScenarioStatus < ActiveRecord::Migration
  def self.up
    change_column :scenarios, :status, :string, default: nil
  end

  def self.down
    change_column :scenarios, :status, :string, default: 'pass'
  end
end
