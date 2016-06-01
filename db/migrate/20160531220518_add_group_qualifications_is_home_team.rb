class AddGroupQualificationsIsHomeTeam < ActiveRecord::Migration
  def self.up
    add_column :predictable_championship_group_qualifications, :is_home_team, :boolean
  end

  def self.down
    remove_column :predictable_championship_group_qualifications, :is_home_team
  end
end
