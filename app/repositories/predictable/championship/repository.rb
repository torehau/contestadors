# Repository base class for predictions for a root aggregate, e.g., Group or Stage.
# Ref.: http://martinfowler.com/eeaCatalog/repository.html
module Predictable
  module Championship
    class Repository

      def initialize(user=nil)
        @user = user
      end

      protected

      # saves predictions for the given set. second parameter must be a hash to the actual
      # predictable instances (e.g., match or table position) keyed by the corresponding ids.
      # The invoker must pass in a block returning the value to be predicted on the predictable instance.
      def save_predictions(predictable_items, predictables_by_id)
        unless @new_predictions
          existing_predictions_by_item_id = @user.predictions.for_items_by_item_id(predictable_items)
          @new_predictions = (existing_predictions_by_item_id.nil? or existing_predictions_by_item_id.empty?)
        end

        predictable_items.each do |item|
          save_prediction(item, existing_predictions_by_item_id, predictables_by_id) do |predictable|
            yield(predictable)
          end
        end
      end

      # creates a new or updates an existing prediction for the given item. The invoker must pass in a
      # block returning the predicted value using the yielded predictable (e.g., match or table position instance)
      def save_prediction(item, existing_predictions_by_item_id, predictable_by_id)
        prediction = @new_predictions ? Prediction::Base.new : existing_predictions_by_item_id[item.id].first
        prediction.core_user_id = @user.id if @new_predictions
        prediction.configuration_predictable_item_id = item.id if @new_predictions
        prediction.predicted_value = yield(predictable_by_id[item.predictable_id])
        prediction.save!
      end

      def update_prediction_progress(percentage_delta)
        if @new_predictions
          @user.prediction_summary.percentage_completed += percentage_delta
          @user.prediction_summary.save!
        end
      end

      # returns a hash for the predictables keyed by the corresponding ids
      def predictables_by_id(predictables)
        Hash[*(predictables).collect{|predictable| [predictable.id, predictable]}.flatten]
      end
    end
  end
end