class CreateCoreUsers < ActiveRecord::Migration
  def self.up
    create_table :core_users do |t|
      t.timestamps
      t.string :email, :null => false
      t.string :name, :null => false
      t.string :crypted_password, :null => false
      t.string :password_salt, :null => false
      t.string :persistence_token, :null => false
      t.integer :login_count, :default => 0, :null => false
      t.datetime :last_request_at
      t.datetime :last_login_at
      t.datetime :current_login_at
      t.string :last_login_ip
      t.string :current_login_ip
    end

    add_index :core_users, :email
    add_index :core_users, :persistence_token
    add_index :core_users, :last_request_at
  end

  def self.down
    drop_table :core_users
  end
end
