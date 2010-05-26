class CreateScoreTablePositions < ActiveRecord::Migration
  def self.up
    create_table :score_table_positions do |t|
      t.integer :participation_id, :null => false
      t.integer :prediction_summary_id, :null => false
      t.integer :contest_instance_id, :null => false
      t.integer :user_id, :null => false
      t.integer :position, :null => false
      t.integer :previous_position
      t.timestamps
    end

    add_index :score_table_positions, :participation_id
    add_index :score_table_positions, :prediction_summary_id
    add_index :score_table_positions, :contest_instance_id
    add_index :score_table_positions, :user_id
  end

  def self.down
    drop_table :score_table_positions
  end
end
