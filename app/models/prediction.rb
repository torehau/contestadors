class Prediction < ActiveRecord::Base
  belongs_to :user
  belongs_to :predictable_item, :class_name => "Configuration::PredictableItem", :foreign_key => "configuration_predictable_item_id"

  validates_presence_of :user_id, :configuration_predictable_item_id, :predicted_value
  validates_numericality_of :user_id, :configuration_predictable_item_id

  # saves predictions for the given user and set. second parameter must be a hash to the actual
  # predictable instances (e.g., match or table position) keyed by the corresponding ids.
  # The invoker must pass in a block returning the value to be predicted on the predictable instance.
  def self.save_predictions(user, set, predictables_by_id)
    predictable_items = set.subset(predictables_by_id.keys)
    existing_predictions_by_item_id = user.predictions.for_items_by_item_id(predictable_items)

    predictable_items.each do |item|
      save_prediction(user, item, existing_predictions_by_item_id, predictables_by_id) do |predictable|
        yield(predictable)
      end
    end
  end

  # creates a new or updates an existing prediction for the given item. The invoker must pass in a
  # block returning the predicted value using the yielded predictable (e.g., match or table position instance)
  def self.save_prediction(user, item, existing_predictions_by_item_id, predictable_by_id)
    is_new = existing_predictions_by_item_id.empty?
    prediction = is_new ? Prediction.new : existing_predictions_by_item_id[item.id].first
    save_predicted_value(user, prediction, is_new, item, yield(predictable_by_id[item.predictable_id]))
  end

  def self.save_predicted_value(user, prediction, is_new, item, value)
    prediction.user_id = user.id if is_new
    prediction.configuration_predictable_item_id = item.id if is_new
    prediction.predicted_value = value
    prediction.save!
  end
end
