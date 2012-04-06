module Predictable
  module Championship
    class GroupAggregate < Predictable::Aggregate
            
      def initialize(aggregate_root_id=nil, contest=nil)
        super(aggregate_root_id, contest)
        @default_error_msg = "Invalid match results given."
      end

      def is_rearrangable?
        (@user and @root.is_rearrangable?)
      end

      def root_id
        @root.name
      end

    protected

      def get_aggregate_root(aggregate_root_id)
        Group.where(:name => aggregate_root_id).last
      end

      def get_aggregate_root_builder(aggregate_root_id)
        GroupAggregateBuilder.new(aggregate_root_id, @contest)
      end

      def validate_new_predictions
        GroupMatchesValidator.new.validate(@new_predictions)
      end

      # saves the predicted group matches and table position for the current user.
      def save_new_aggregate_predictions
        save_group_match_predictions
        save_table_position_predictions
        save_next_stage_promotion_predictions
      end

      def notify
        summary.predict_group(@root.name)
      end

      def get_existing_predictions
        return nil unless @user and @contest
        set = promotion_stage_set
        
        winner_stage_team_item = set.predictable_item(@root.winner_stage_team.id)
        winner_prediction = @user.prediction_for(winner_stage_team_item)
        runner_up_stage_team_item = set.predictable_item(@root.runner_up_stage_team.id)
        runner_up_prediction = @user.prediction_for(runner_up_stage_team_item)

        existing_predictions = {}
        existing_predictions[:winner] = winner_prediction.predicted_value if winner_prediction
        existing_predictions[:runner_up] = runner_up_prediction.predicted_value if runner_up_prediction
        existing_predictions
      end

      def invalidates_dependant_aggregates?
        not (@existing_predictions[:winner].eql?(@new_predictions.winner.id.to_s) and
             @existing_predictions[:runner_up].eql?(@new_predictions.runner_up.id.to_s))
      end

    private

      def save_group_match_predictions
        #set = Configuration::Set.find_by_description "Group #{@root.name} Matches"
        set = @contest.set("Group #{@root.name} Matches")

        Prediction.save_predictions(@user, set, @root.matches_by_id) do |match|
          match.home_team_score + '-' + match.away_team_score
        end
      end

      def save_table_position_predictions
        #set = Configuration::Set.find_by_description "Group #{@root.name} Table"
        set = @contest.set("Group #{@root.name} Table")

        Prediction.save_predictions(@user, set, predictables_by_id(@root.table_positions)) do |table_position|
          table_position.display_order.to_s
        end
      end

      def save_next_stage_promotion_predictions
        #set = Configuration::Set.find_by_description "Teams through to Round of 16"
        set = promotion_stage_set

        Prediction.save_predictions(@user, set, @root.stage_teams_by_id) do |stage_team|
          stage_team.team.id.to_s
        end
      end

      def promotion_stage_set
        stage = @root.promotion_stage
        @contest.set("Teams through to #{stage.description}")#Configuration::Set.find_by_description "Teams through to Round of 16"
      end
    end
  end
end
