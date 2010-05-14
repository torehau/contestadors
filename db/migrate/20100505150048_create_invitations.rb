class CreateInvitations < ActiveRecord::Migration
  def self.up
    create_table :invitations do |t|
      t.string :name,                 :null => false
      t.string :email,                :null => false
      t.integer :contest_instance_id, :null => false
      t.integer :sender_id,           :null => false
      t.integer :existing_user_id
      t.string :state
      t.timestamps
    end

    add_index :invitations, :email
    add_index :invitations, :contest_instance_id
    add_index :invitations, :existing_user_id
  end

  def self.down
    drop_table :invitations
  end
end
