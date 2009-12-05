class CreatePredictableChampionshipTeams < ActiveRecord::Migration
  def self.up
    create_table :predictable_championship_teams do |t|
      t.string :code
      t.string :name
      t.string :country_flag
      t.timestamps
    end
  end

  def self.down
    drop_table :predictable_championship_teams
  end
end
