# Create the initial tables
class CreateInitial < ActiveRecord::Migration
  def self.up
    create_table :test_suites do |t|
      t.column :name,           :string,    null: true
      t.column :owner,          :string,    null: false
      t.column :env,            :string,    null: false
      t.column :guid,           :string,    null: false
      t.column :requested_time, :datetime,  null: false
      t.column :finished_time,  :datetime,  null: true
      t.column :complete,       :boolean,   null: true
    end
    
    create_table :features do |t|
      t.column :test_suite_id,  :integer, null: false
      t.column :name,           :string,  null: false
      t.column :filename,       :string,  null: false
      t.column :owned_by,       :string,  null: true
    end

    create_table :scenarios do |t|
      t.column :feature_id, :integer,   null: false
      t.column :name,       :string,    null: false
      t.column :filename,   :string,    null: false
      t.column :owned_by,   :string,    null: true
      t.column :end_time,   :datetime,  null: true
      t.column :runtime,    :decimal,   null: true
      t.column :steps,      :text,      null: true
      t.column :exception,  :text,      null: true
    end



  end

  def self.down
    drop_table :scenarios
    drop_table :features
    drop_table :test_suites
  end
end
