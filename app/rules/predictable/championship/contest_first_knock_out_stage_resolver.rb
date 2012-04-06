module Predictable
  module Championship
    class ContestFirstKnockOutStageResolver

      def resolve(contest)
        state = contest.prediction_states.where(:aggregate_root_type => "stage").first
        Stage.find(state.aggregate_root_id)
      end
    end
  end
end
