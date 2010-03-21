class Prediction < ActiveRecord::Base
  belongs_to :user
  belongs_to :predictable_item, :class_name => "Configuration::PredictableItem", :foreign_key => "configuration_predictable_item_id"

  validates_presence_of :user_id, :configuration_predictable_item_id, :predicted_value
  validates_numericality_of :user_id, :configuration_predictable_item_id
end
