class CreatePredictionSummaries < ActiveRecord::Migration
  def self.up
    create_table :prediction_summaries do |t|
      t.string :state
      t.integer :map, :default => 500
      t.integer :user_id, :null => false
      t.integer :total_score, :default => 0
      t.integer :previous_score, :default => 0
      t.integer :previous_map, :default => 0

      t.timestamps
    end

    add_index :prediction_summaries, :user_id
  end

  def self.down
    drop_table :prediction_summaries
  end
end
