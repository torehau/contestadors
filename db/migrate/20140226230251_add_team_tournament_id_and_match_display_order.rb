class AddTeamTournamentIdAndMatchDisplayOrder < ActiveRecord::Migration
  def self.up
    add_column :predictable_championship_teams, :tournament_id, :int
    add_column :predictable_championship_matches, :display_order, :int
  end

  def self.down
    remove_column :predictable_championship_matches, :display_order
    remove_column :predictable_championship_teams, :tournament_id
  end
end
