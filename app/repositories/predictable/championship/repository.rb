module Predictable
  module Championship

    # Base class for retreiving, saving and updating prediction aggregates.
    # Subclasses must implement all abstract methods.
    class Repository

      # sets the contest and user for which the predictions belongs.
      def initialize(contest=nil, user=nil)
        @contest = contest
        @user = user
      end

      # retreives the aggregate with the predicted values, or default values if not
      # been predicted by the user (or if no user is specified, i.e., not signed in
      # guest user)
      def get(aggregate_root_id)
        @aggregate = new_aggregate(aggregate_root_id)
        @aggregate.set_existing_predictions(@user) if @user
        Predictable::Result.new(@aggregate)
      end

      # saves the predictions in the provided input hash if the user is signed in
      # If not signed in, the aggregate root instance variable will only be updated
      # with the predicted values, and these will not be saved to the db
      def save(aggregate_root_id, new_predictions)
        @aggregate = new_aggregate(aggregate_root_id)
        @aggregate.set_new_predictions(new_predictions, @user)
        @aggregate.validate
        @aggregate.save unless @aggregate.invalid? or @aggregate.no_user?
        Predictable::Result.new(@aggregate)
      end

      # updates a given aggregate based on the provided data in the input params hash.
      def update(aggregate_root_id, params)
        raise "Abstract method. Must be implemented in a concrete subclass."
      end

      # deletes all predictions for the given items placed by the user
      def delete(predictable_items, user)
        if user and not predictable_items.empty?
          Prediction.transaction do
            Prediction.delete_all(["user_id = ? and configuration_predictable_item_id in (?)", user.id, predictable_items])
          end
        end
      end

    protected

      # Constructs a new aggregate with the appropriate type for the given root id.
      def new_aggregate(aggregate_root_id)
        raise 'Abstract method! Must be implemented in subclass.'
      end
    end
  end
end