module Predictable
  module Championship
    class StageAggregate < Predictable::Aggregate

      def initialize(aggregate_root_id=nil, contest=nil)
        super(aggregate_root_id, contest)
        @default_error_msg = "Identical knockout stage predictions given. No changes saved."
      end

      def set_existing_predictions(user)
        @user = user
        @result = @builder.build_from_existing(@user)
        @result
      end

      def redirect_on_save?
        true
      end

      def root_id
        @root.permalink
      end

      def error_msg
        has_validation_errors? ? @validation_errors.values.first : @default_error_msg
      end

    protected

      def get_aggregate_root(aggregate_root_id)
        aggregate_root_id ||="round-of-16"
        Stage.from_permalink(aggregate_root_id)
      end

      def get_aggregate_root_builder(aggregate_root_id)
        StageAggregateBuilder.new(aggregate_root_id, @contest)
      end

      def validate_new_predictions
        errors = KnockoutStageValidator.new(@contest).validate(@new_predictions, summary)
        reset_root_to_current_stage unless errors.empty?
        errors
      end

      def get_new_predictions(new_predictions)
        set_winners_by_match_id(new_predictions)
        set_match_winners
        @root
      end

      def set_winners_by_match_id(new_predictions)
        @winners_by_match_id = {}
        new_predictions.each do |match_id, match|
          @winners_by_match_id[match_id.to_i] = Predictable::Championship::Team.find(match[:winner].to_i)
        end
      end

      def set_match_winners
        @root.matches.each{|match| match.winner = @winners_by_match_id[match.id]}
      end

      def get_existing_predictions
        return nil unless @user
        @user.predictions.for_items_by_value(get_predictable_items)
      end

      def get_predictable_items
        @contest.set("Teams through to #{@root.next.description}").predictable_items
      end

      def invalidates_dependant_aggregates?
        @root.matches.each do |match|
          return true unless @existing_predictions.has_key?(match.winner.id.to_s)
        end
        false
      end

      def save_new_aggregate_predictions
        unless equals_existing_predictions?
          save_stage_team_predictions
        else
          @validation_errors[@root.id] = @default_error_msg
        end
      end

      def equals_existing_predictions?
        self.state.eql?("update")
      end

      def notify
        summary.predict_stage(@root.description)
        @root = @root.next
      end

    private

      def save_stage_team_predictions
        set = @contest.set "Teams through to #{@root.next.description}"

        Prediction.save_predictions(@user, set, teams_through_to_next_stage_by_id) do |stage_team|
          stage_team.team.id.to_s
        end
      end

      def teams_through_to_next_stage_by_id
        from_stage_matches_by_id = @root.matches_by_id
        stage_teams_by_id = {}
        
        @root.next.stage_teams.each do |stage_team|
          match = stage_team.qualified_from_match
          stage_team.team = from_stage_matches_by_id[match.id].winner
          stage_teams_by_id[stage_team.id] = stage_team
        end
        stage_teams_by_id
      end

      def reset_root_to_current_stage
        current_prediction_state = @contest.prediction_state(summary.state)
        next_prediction_state = current_prediction_state.next
        if next_prediction_state
          @root = Predictable::Championship::Stage.from_permalink(next_prediction_state.permalink)
        end
      end
    end
  end
end