class CreatePredictableChampionshipThirdPlaceGroupTeamQualifications < ActiveRecord::Migration
  def self.up
    create_table :predictable_championship_third_place_group_team_qualifications do |t|
      t.integer :predictable_championship_best_ranked_group_id
      t.integer :predictable_championship_group_id
      t.integer :predictable_championship_stage_team_id
      t.timestamps
    end
  end

  def self.down
    drop_table :predictable_championship_third_place_group_team_qualifications
  end
end
