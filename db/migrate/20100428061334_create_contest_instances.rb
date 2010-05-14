class CreateContestInstances < ActiveRecord::Migration
  def self.up
    create_table :contest_instances do |t|
      t.string :name,                      :limit   => 50, :null => false
      t.string :permalink,                 :null => false
      t.integer :configuration_contest_id, :null => false
      t.integer :admin_user_id,            :null => false
      t.string :uuid,                      :null => false
      t.text :description
      t.timestamps
    end

    add_index :contest_instances, :admin_user_id
    add_index :contest_instances, :permalink
    add_index :contest_instances, :uuid
  end

  def self.down
    drop_table :contest_instances
  end
end
