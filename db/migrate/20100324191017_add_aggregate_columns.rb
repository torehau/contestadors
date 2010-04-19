class AddAggregateColumns < ActiveRecord::Migration
  def self.up
    add_column :configuration_prediction_states, :aggregate_root_type, :string
    add_column :configuration_prediction_states, :aggregate_root_id, :integer
    add_column :configuration_sets, :configuration_prediction_state_id, :integer
  end

  def self.down
    remove_column :configuration_prediction_states, :aggregate_root_type
    remove_column :configuration_prediction_states, :aggregate_root_id
    remove_column :configuration_sets, :configuration_prediction_state_id
  end
end
