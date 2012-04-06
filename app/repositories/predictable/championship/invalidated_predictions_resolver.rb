module Predictable
  module Championship
    # Identifies any invalidated predictions for a user. I.e., any predictions
    # placed by the user which isassociated with a prediction state following
    # the user's current prediction state
    class InvalidatedPredictionsResolver

      def initialize(user, contest)
        @user = user
        @contest = contest
        @user_prediction_state = @user.summary_of(@contest).state
      end

      # Returnes the predictable items for knockout stage predictions that have
      # become invalidated
      def get_predictable_items_for_invalidated_predictions
        items = []
        stages = get_stages_to_delete_predictions_for
        return items if stages.empty?

        stages.each do |stage|
          set = @contest.set("Teams through to #{stage.description}")
          set.predictable_items.each {|item| items << item.id} if set
        end
        set = @contest.set("Third Place Team")
        items << set.predictable_items.first.id if set
        set = @contest.set("Winner Team")
        items << set.predictable_items.first.id
        items.uniq
      end

    private
    
      def get_stages_to_delete_predictions_for
        stages_predicted_explicitly = Predictable::Championship::Stage.explicit_predicted_knockout_stages
        return stages_predicted_explicitly if is_group_stage_prediction?
        prediction_state = @contest.prediction_state(@user_prediction_state)
        current_stage = Predictable::Championship::Stage.from_permalink(prediction_state.permalink)
        next_stage = current_stage.next
        stages = []
        while next_stage.next do
          stages << next_stage.next
          next_stage = next_stage.next
        end
        stages
      end

      def is_group_stage_prediction?
        %w{a b c d e f g h}.include?(@user_prediction_state)
      end
    end
  end
end
