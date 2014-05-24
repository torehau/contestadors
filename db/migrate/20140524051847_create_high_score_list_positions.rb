class CreateHighScoreListPositions < ActiveRecord::Migration
  def self.up
    create_table :high_score_list_positions do |t|
      t.integer :prediction_summary_id
      t.integer :user_id
      t.integer :configuration_contest_id
      t.integer :position
      t.integer :previous_position
      t.boolean :has_predictions

      t.timestamps
    end
  end

  def self.down
    drop_table :high_score_list_positions
  end
end
