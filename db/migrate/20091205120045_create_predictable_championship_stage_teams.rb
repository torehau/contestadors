class CreatePredictableChampionshipStageTeams < ActiveRecord::Migration
  def self.up
    create_table :predictable_championship_stage_teams do |t|
      t.integer :predictable_championship_stage_id
      t.integer :predictable_championship_team_id
      t.timestamps
    end
  end

  def self.down
    drop_table :predictable_championship_stage_teams
  end
end
