class AddInvitationTokenColumn < ActiveRecord::Migration
  def self.up
    add_column :invitations, :token, :string
    add_index :invitations, :token
  end

  def self.down
    remove_column :invitations, :token
  end
end
