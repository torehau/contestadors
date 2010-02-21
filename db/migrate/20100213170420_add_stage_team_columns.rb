class AddStageTeamColumns < ActiveRecord::Migration
  def self.up
    add_column :predictable_championship_stage_teams, :predictable_championship_match_id, :integer
    add_column :predictable_championship_stage_teams, :is_home_team, :boolean
  end

  def self.down
    remove_column :predictable_championship_stage_teams, :predictable_championship_match_id
    remove_column :predictable_championship_stage_teams, :is_home_team
  end
end
