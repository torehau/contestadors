class AddPredictionStateColumn < ActiveRecord::Migration
  def self.up
    add_column :configuration_prediction_states, :preview_available, :boolean, :default => false
    add_column :configuration_prediction_states, :position, :integer
  end

  def self.down
    remove_column :configuration_prediction_states, :preview_available
    remove_column :configuration_prediction_states, :position
  end
end
