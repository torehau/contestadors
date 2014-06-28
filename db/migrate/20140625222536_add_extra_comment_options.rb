class AddExtraCommentOptions < ActiveRecord::Migration
  def self.up
    add_column :comments, :removed, :boolean
    add_column :comments, :blocked, :boolean
    add_column :users, :email_notifications_on_comments, :boolean
  end

  def self.down
    remove_column :users, :email_notifications_on_comments
    remove_column :comments, :blocked
    remove_column :comments, :removed
  end
end
