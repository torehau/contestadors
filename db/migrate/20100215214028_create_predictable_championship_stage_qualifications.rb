class CreatePredictableChampionshipStageQualifications < ActiveRecord::Migration
  def self.up
    create_table :predictable_championship_stage_qualifications do |t|
      t.integer :predictable_championship_match_id
      t.integer :predictable_championship_stage_team_id
      t.boolean :is_winner

      t.timestamps
    end
  end

  def self.down
    drop_table :predictable_championship_stage_qualifications
  end
end
