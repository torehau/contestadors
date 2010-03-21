class CreateConfigurationPredictionStates < ActiveRecord::Migration
  def self.up
    create_table :configuration_prediction_states do |t|
      t.integer :configuration_contest_id
      t.string :state_name
      t.string :permalink
      t.string :next_state_name
      t.integer :progress_delta
      t.integer :progress_accumulated

      t.timestamps
    end
  end

  def self.down
    drop_table :configuration_prediction_states
  end
end
