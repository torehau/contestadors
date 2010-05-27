module Predictable
  module Championship
    class GroupRepository < Repository

      def initialize(contest=nil, user=nil)
        super(contest, user)
      end

      # updates predictions for two group table positions by moving the prediction for
      # the given position according to the specified move operation (:up or :down).
      # The current prediction for the new position is swapped accordingly.
      # If this affects the predicted group winner and runner up teams, this will
      # be updated as well.
      def update(aggregate_root_id, params)
        result = get(aggregate_root_id)
        aggregate = result.current
        updated_predictions = GroupTableRearranger.new(aggregate.root, @user, params).rearrange

        unless updated_predictions.empty?
          Prediction.transaction do
            updated_predictions.each {|prediction| prediction.save!}

            if updated_predictions.size > 2
              @summary ||= @user.summary_of(@contest)
              @summary.predict_group(aggregate.root.name)
            end
          end
        end
        aggregate.root.sort_group_table(false)
        result
      end

    protected

      def new_aggregate(aggregate_root_id)
        GroupAggregate.new(aggregate_root_id, @contest)
      end
    end
  end
end