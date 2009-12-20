class CreatePredictableChampionshipPlayers < ActiveRecord::Migration
  def self.up
    create_table :predictable_championship_players do |t|
      t.string :name
      t.integer :predictable_championship_team_id
      t.integer :goals, :default => 0
      t.boolean :selectable, :default => true
      t.timestamps
    end
  end

  def self.down
    drop_table :predictable_championship_players
  end
end
