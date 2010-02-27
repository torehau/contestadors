module Predictable
  module Championship

    # Base class for retreiving, saving and updating prediction aggregates.
    # Subclasses must implement all empty protected methods defined in this class.
    class Repository

      def initialize(aggregate)
        @aggregate = aggregate
        @user = @aggregate.user
        @root = get_aggregate_root(@aggregate.id)
        @aggregate.root = @root
        @predictable_set = get_predictable_set
      end

      # retreives the aggregate with the predicted values, or default values if not
      # been predicted by the user (or if no user is specified, i.e., not signed in
      # guest user)
      def get
        @existing_predicted_root = nil

        if @user and has_existing_predictions?
          @aggregate.set_root_from_existing_predictions(build_aggregate_root_from_existing_predictions)
        end
        @aggregate
      end

      # saves the predictions in the provided input hash if the user is signed in
      # If not signed in, the aggregate root instance variable will only be updated
      # with the predicted values, and these will not be saved in the db
      def save
        @root = build_aggregate_root_from_new_predictions
        @validation_errors = validate(@root)

        if @user and @validation_errors.empty?
          begin
            save_predictions_for_aggregate
          rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid
            # NOP
          end
        else
          @aggregate.validation_errors = @validation_errors
        end
        @aggregate.has_existing_predictions = !@new_predictions
        @aggregate.root = @root
        @aggregate
      end

      protected
      

      def get_aggregate_root(aggregate_root_id)
      end

      def get_predictable_set
      end

      def has_existing_predictions?
        @predictions_by_item_id = @user.predictions.by_predictable_item(@predictable_set)
        (@predictions_by_item_id and not @predictions_by_item_id.empty?)
      end

      def build_aggregate_root_from_existing_predictions
      end

      def build_aggregate_root_from_new_predictions
      end

      def validate(predicted_aggregate_root)
      end

      def save_predictions_for_aggregate
      end

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