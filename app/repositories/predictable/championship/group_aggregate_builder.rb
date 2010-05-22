module Predictable
  module Championship
    class GroupAggregateBuilder
      def initialize(group_name)
        @group_name = group_name
        @predictable_set = Configuration::Set.find_by_description "Group #{@group_name} Matches"
      end

      def build_from_new(predictions)
        @root = Group.find_by_name(@group_name)
        group_from_new_predictions(predictions)
      end

      def build_from_existing(user)
        @predictions_by_item_id = user.predictions.by_predictable_item(@predictable_set)
        return nil unless (@predictions_by_item_id and not @predictions_by_item_id.empty?)
        @root = Group.find_by_name(@group_name)
        group_from_existing_predictions(user)
      end

    private

      # builds the group results using the provided request parameter hash
      def group_from_new_predictions(predicted_scores_by_match_id)

        if predicted_scores_by_match_id and predicted_scores_by_match_id.length > 0
          set_predicted_match_results do |item|
#            prediction = predicted_scores_by_match_id[item.predictable_id.to_s]
#            prediction[:home_team_score] + '-' + prediction[:away_team_score]
            predicted_scores_by_match_id[item.predictable_id.to_s]
          end
          GroupTableCalculator.new(@root).calculate(true)
        end
        @root
      end

      def group_from_existing_predictions(user)
        set_predicted_match_results do |item|
#          prediction = @predictions_by_item_id[item.id].first
#          prediction.predicted_value
          prediction = @predictions_by_item_id[item.id].first
          scores = prediction.predicted_value.split('-')
          {:home_team_score => scores[0], :away_team_score => scores[1]}
        end

        @group_table_set = Configuration::Set.find_by_description "Group #{@root.name} Table"
        set_predicted_table_positions(user.predictions.by_predictable_item(@group_table_set))
        GroupTableCalculator.new(@root).calculate(false)
      end

      # sets the predicted results for the group matches. The invoker must pass in a block
      # returning the predicted result of the match proxied by the yielded item.
      def set_predicted_match_results
        matches_by_id = @root.matches_by_id
        predicted_matches = []

        @predictable_set.predictable_items.each do |item|
          match = matches_by_id[item.predictable_id]
          predicted_scores = yield(item)
          match.set_individual_team_scores(predicted_scores[:home_team_score], predicted_scores[:away_team_score])
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
    end
  end
end
