class AddUserAllowNameInHighScoreLists < ActiveRecord::Migration
  def self.up
    add_column :users, :allow_name_in_high_score_lists, :boolean
  end

  def self.down
    remove_column :users, :allow_name_in_high_score_lists
  end
end
