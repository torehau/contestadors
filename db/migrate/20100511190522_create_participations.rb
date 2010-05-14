class CreateParticipations < ActiveRecord::Migration
  def self.up
    create_table :participations do |t|
      t.integer :contest_instance_id, :null => false
      t.integer :user_id,             :null => false
      t.integer :invitation_id
      t.timestamps
    end

    add_index :participations, :contest_instance_id
    add_index :participations, :user_id
  end

  def self.down
    drop_table :participations
  end
end
