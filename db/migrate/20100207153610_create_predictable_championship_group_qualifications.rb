class CreatePredictableChampionshipGroupQualifications < ActiveRecord::Migration
  def self.up
    create_table :predictable_championship_group_qualifications do |t|
      t.integer :predictable_championship_group_id
      t.integer :group_pos
      t.integer :predictable_championship_match_id

      t.timestamps
    end
  end

  def self.down
    drop_table :predictable_championship_group_qualifications
  end
end
