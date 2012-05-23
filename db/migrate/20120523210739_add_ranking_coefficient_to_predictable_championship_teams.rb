class AddRankingCoefficientToPredictableChampionshipTeams < ActiveRecord::Migration
  def self.up
    add_column :predictable_championship_teams, :ranking_coefficient, :int
  end

  def self.down
    remove_column :predictable_championship_teams, :ranking_coefficient
  end
end
