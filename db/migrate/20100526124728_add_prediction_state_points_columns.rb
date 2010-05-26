class AddPredictionStatePointsColumns < ActiveRecord::Migration
  def self.up
    add_column :configuration_prediction_states, :points_delta, :integer
    add_column :configuration_prediction_states, :points_accumulated, :integer
  end

  def self.down
    remove_column :configuration_prediction_states, :points_delta
    remove_column :configuration_prediction_states, :points_accumulated
  end
end
