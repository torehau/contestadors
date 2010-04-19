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
        @group = Group.find_by_name(aggregate_root_id)
        @group_table_set = Configuration::Set.find_by_description "Group #{@group.name} Table"
        @round_of_16_qualified_teams_set = Configuration::Set.find_by_description "Teams through to Round of 16"
        predictable_item = @group_table_set.predictable_item(params[:id])
        prediction = @user.prediction_for(predictable_item)
        current_value = prediction.predicted_value.to_i
        updated_value = params[:command].eql?("up") ? (current_value - 1) : (current_value + 1)
        prediction_to_swap_value_with = @user.prediction_with_value(updated_value.to_s, @group_table_set)

        Prediction.transaction do

          @summary ||= @user.summary_of(@contest)
          
          if [current_value, updated_value].include?(1)
            swap_stage_team_predictions_for_winner_and_runner_up
            @summary.predict_group(@group.name)
          elsif [current_value, updated_value].include?(2) and [current_value, updated_value].include?(3)
            set_current_third_place_group_position_as_runner_up_stage_team
            @summary.predict_group(@group.name)
          end

          prediction.predicted_value = updated_value.to_s
          prediction_to_swap_value_with.predicted_value = current_value.to_s
          prediction.save!
          prediction_to_swap_value_with.save!
        end
      end

    protected

      def new_aggregate(aggregate_root_id)
        GroupAggregate.new(aggregate_root_id, @contest)
      end

    private

      # swaps the predictions for group winner and runner up stage teams
      # qualified for the Round of 16 stage
      def swap_stage_team_predictions_for_winner_and_runner_up
        stage_teams_by_id = @group.stage_teams_by_id
        items = @round_of_16_qualified_teams_set.subset(stage_teams_by_id.keys)
        predictions = @user.predictions_for_subset(items)
        first_val = predictions[0].predicted_value
        second_val = predictions[1].predicted_value
        predictions[0].predicted_value = second_val
        predictions[0].save!
        predictions[1].predicted_value = first_val
        predictions[1].save!
      end

      # replaces the current runner up stage team predictions, with the team
      # currently predicted at the 3rd place group table position
      def set_current_third_place_group_position_as_runner_up_stage_team
        runner_up_stage_team = @group.runner_up_stage_team
        runner_up_stage_team_item = @round_of_16_qualified_teams_set.predictable_item(runner_up_stage_team.id)
        runner_up_prediction = @user.prediction_for(runner_up_stage_team_item)

        third_place_table_pos_prediction = @user.prediction_with_value("3", @group_table_set)
        third_place_table_pos_item = third_place_table_pos_prediction.predictable_item
        third_place_table_pos = third_place_table_pos_item.predictable

        runner_up_prediction.predicted_value = third_place_table_pos.team.id
        runner_up_prediction.save!
      end
    end
  end
end