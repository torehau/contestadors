class CreatePredictableChampionshipStages < ActiveRecord::Migration
  def self.up
    create_table :predictable_championship_stages do |t|
      t.string :description

      t.timestamps
    end
  end

  def self.down
    drop_table :predictable_championship_stages
  end
end
