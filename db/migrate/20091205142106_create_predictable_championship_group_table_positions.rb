class CreatePredictableChampionshipGroupTablePositions < ActiveRecord::Migration
  def self.up
    create_table :predictable_championship_group_table_positions do |t|
      t.integer :pos
      t.integer :predictable_championship_group_id
      t.integer :predictable_championship_team_id

      t.timestamps
    end
  end

  def self.down
    drop_table :predictable_championship_group_table_positions
  end
end
