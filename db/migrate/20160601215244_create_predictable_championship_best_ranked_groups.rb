class CreatePredictableChampionshipBestRankedGroups < ActiveRecord::Migration
  def self.up
    create_table :predictable_championship_best_ranked_groups do |t|
      t.string :permutation
      t.timestamps
    end
  end

  def self.down
    drop_table :predictable_championship_best_ranked_groups
  end
end
