class CreatePredictionSummaries < ActiveRecord::Migration
  def self.up
    create_table :prediction_summaries do |t|
      t.string :state
      t.integer :map, :default => 650
      t.integer :core_user_id, :null => false
      t.integer :total_score, :default => 0
      t.integer :previous_score, :default => 0
      t.integer :previous_map, :default => 0
      t.integer :percentage_completed, :default => 0

      t.timestamps
    end

    add_index :prediction_summaries, :core_user_id
  end

  def self.down
    drop_table :prediction_summaries
  end
end
