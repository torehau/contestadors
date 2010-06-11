class AddPredictableItemAndPredictionColumns < ActiveRecord::Migration
  def self.up
    add_column :configuration_predictable_items, :state, :string, :default => "unsettled"
    add_column :predictions, :objectives_meet, :integer, :default => 0
    add_column :predictions, :received_points, :integer, :default => 0
  end

  def self.down
    remove_column :configuration_prediction_items, :state
    remove_column :predictions, :objectives_meet
    remove_column :predictions, :received_points
  end
end
