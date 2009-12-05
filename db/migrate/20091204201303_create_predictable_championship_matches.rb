class CreatePredictableChampionshipMatches < ActiveRecord::Migration
  def self.up
    create_table :predictable_championship_matches do |t|
      t.string :description
      t.string :score
      t.string :result
      t.datetime :play_date
      t.integer :home_team_id
      t.integer :away_team_id
      t.integer :predictable_championship_stage_id
      t.timestamps
    end
  end

  def self.down
    drop_table :predictable_championship_matches
  end
end
