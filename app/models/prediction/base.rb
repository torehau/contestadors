module Prediction
  class Base < ActiveRecord::Base
    set_table_name("core_predictions")
    belongs_to :user, :class_name => "Core::User", :foreign_key => 'core_user_id'
    has_one :predictable_item, :class_name => "Configuration::PredictableItem", :foreign_key => "configuration_predictable_item_id"

    validates_presence_of :core_user_id, :configuration_predictable_item_id, :predicted_value
    validates_numericality_of :core_user_id, :configuration_predictable_item_id
  end
end
