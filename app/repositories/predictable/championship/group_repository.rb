module Predictable
  module Championship
    class GroupRepository < Repository
      PERCENTAGE_COMPLETED_FOR_GROUP = 9

      # sets the user for which the predictions belongs, the group and the prediction sets
      # defining this aggregate of predictions
      def initialize(aggregate=nil)
        super(aggregate)
        @group_table_set = Configuration::Set.find_by_description "Group #{@root.name} Table"
        @round_of_16_qualified_teams_set = Configuration::Set.find_by_description "Teams through to Round of 16"
      end

      # updates predictions for two group table positions by moving the prediction for
      # the given position according to the specified move operation (:up or :down).
      # The current prediction for the new position is swapped accordingly.
      # If this affects the predicted group winner and runner up teams, this will
      # be updated as well.
      def update
        predictable_item = @group_table_set.predictable_item(@aggregate.member_id)
        prediction = @user.prediction_for(predictable_item)
        current_value = prediction.predicted_value.to_i
        updated_value = @aggregate.command.eql?(:up) ? (current_value - 1) : (current_value + 1)
        prediction_to_swap_value_with = @user.prediction_with_value(updated_value.to_s, @group_table_set)

        Prediction::Base.transaction do

          if [current_value, updated_value].include?(1)
            swap_stage_team_predictions_for_winner_and_runner_up
            @user.prediction_summary.predict_group(@root.name)
          elsif [current_value, updated_value].include?(2) and [current_value, updated_value].include?(3)
            set_current_third_place_group_position_as_runner_up_stage_team
            @user.prediction_summary.predict_group(@root.name)
          end

          prediction.predicted_value = updated_value.to_s
          prediction_to_swap_value_with.predicted_value = current_value.to_s
          prediction.save!
          prediction_to_swap_value_with.save!
        end
      end

      protected

      def get_aggregate_root(aggregate_root_id)
        aggregate_root_id ||="A"
        Group.find_by_name(aggregate_root_id)
      end

      def get_predictable_set
        Configuration::Set.find_by_description "Group #{@root.name} Matches"
      end

      # builds the group results using the predictions stored in the db for the given user
      def build_aggregate_root_from_existing_predictions
        set_predicted_match_results do |item|
          prediction = @predictions_by_item_id[item.id].first
          prediction.predicted_value
        end
        set_predicted_table_positions(@user.predictions.by_predictable_item(@group_table_set))
        GroupTableCalculator.new(@root).calculate(false)
      end

      def build_aggregate_root_from_new_predictions
        group_from_new_predictions(@aggregate.new_predictions)
      end

      def validate(predicted_aggregate_root)
        GroupMatchesValidator.new.validate(predicted_aggregate_root)
      end

      def save_predictions_for_aggregate
        save_predictions_for_group
        @user.prediction_summary.predict_group(@root.name)
      end

      private

      # builds the group results using the provided request parameter hash
      def group_from_new_predictions(predicted_scores_by_match_id)

        if predicted_scores_by_match_id and predicted_scores_by_match_id.length > 0
          set_predicted_match_results do |item|
            prediction = predicted_scores_by_match_id[item.predictable_id.to_s]
            prediction[:home_team_score] + '-' + prediction[:away_team_score]
          end
          GroupTableCalculator.new(@root).calculate(true)
        end
        @root
      end

      # sets the predicted results for the group matches. The invoker must pass in a block
      # returning the predicted result of the match proxied by the yielded item.
      def set_predicted_match_results
        matches_by_id = @root.matches_by_id
        predicted_matches = []

        @predictable_set.predictable_items.each do |item|
          match = matches_by_id[item.predictable_id]
          predicted_score = yield(item)
          match.set_individual_team_scores(predicted_score)
          predicted_matches << match
        end
        @root.matches = predicted_matches
      end

      # sets the predicted display order for the group table positions.
      def set_predicted_table_positions(table_position_predictions_by_item_id)
        predictable_items_by_predictable_id = @group_table_set.predictable_items.by_predictable_id

        @root.table_positions.each do |table_position|
          item = predictable_items_by_predictable_id[table_position.id].first
          table_position.display_order = table_position_predictions_by_item_id[item.id].first.predicted_value.to_i
        end
      end

      # saves the predicted group matches and table position for the current user.
      def save_predictions_for_group
        Prediction::Base.transaction do
          
          save_predictions(@predictable_set.predictable_items, @root.matches_by_id) do |match|
            match.home_team_score + '-' + match.away_team_score
          end

          save_predictions(@group_table_set.predictable_items, predictables_by_id(@root.table_positions)) do |table_position|
            table_position.display_order.to_s
          end

          stage_teams_by_id = @root.stage_teams_by_id
          items = @round_of_16_qualified_teams_set.subset(stage_teams_by_id.keys)
          save_predictions(items, stage_teams_by_id) do |stage_team|
            stage_team.team.id.to_s
          end

          update_prediction_progress(PERCENTAGE_COMPLETED_FOR_GROUP)
        end
      end

      # swaps the predictions for group winner and runner up stage teams
      # qualified for the Round of 16 stage
      def swap_stage_team_predictions_for_winner_and_runner_up
        stage_teams_by_id = @root.stage_teams_by_id
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
        runner_up_stage_team = @root.runner_up_stage_team
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