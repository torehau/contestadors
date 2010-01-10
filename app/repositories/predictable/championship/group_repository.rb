# Repository implementation of the root aggregate for predictions related to a
# Predictable::Championship::Group, i.e., group matches and table positions.
# Ref.: http://martinfowler.com/eeaCatalog/repository.html
module Predictable
  module Championship
    class GroupRepository
      # sets the user for which the predictions belongs, the group and the prediction sets
      # defining this aggregate of predictions
      def initialize(user=nil, group_name="A")
        @user = user
        @group = Group.find_by_name group_name
        @group_matches_set = Configuration::Set.find_by_description "Group #{@group.name} Matches"
        @group_table_set = Configuration::Set.find_by_description "Group #{@group.name} Table"
        @sort_table = false
      end

      # retreives the group with the predicted values, or default values if not
      # been predicted by the user (or if no  user is specified, i.e., not signed in
      # guest user)
      def get
        if @user
          return build_group_results_from_existing_predictions
        end
        [@group, false]
      end

      # saves the predictions in the provided input hash if the user is signed in
      # If not signed in, the group instance variable will only be updated with the
      # predicted values, and these will not be saved in the db
      def save(predicted_group)
        @group = build_group_results_from_new_predictions(predicted_group)
        
        if @user
          save_predictions_for_group_matches
        end
        
        return [@group, true]
        rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid
          [@group, false]
      end

      private

      # retreive predictions from db
      def build_group_results_from_existing_predictions
        predictions_by_item_id = @user.predictions.by_predictable_item(@group_matches_set)
        predictions_exists_for_user = (predictions_by_item_id and not predictions_by_item_id.empty?)

        if predictions_exists_for_user
          return build_group_results_from_predictions do |item|
            prediction = predictions_by_item_id[item.id].first
            predicted_score = prediction.predicted_value
          end
        end
        return @group, predictions_exists_for_user
      end

      # retreive predictions from request parameter hash
      def build_group_results_from_new_predictions(params)
        predicted_scores_by_match_id = params[:predicted_matches]

        if predicted_scores_by_match_id and predicted_scores_by_match_id.length > 0
          return build_group_results_from_predictions do |item|
            prediction = predicted_scores_by_match_id[item.predictable_id.to_s]
            predicted_score = prediction[:home_team_score] + '-' + prediction[:away_team_score]
          end
        end
        @group
      end

      def build_group_results_from_predictions
        @sort_table = true
        matches_by_id = @group.matches_by_id
        predicted_matches = []

        @group_matches_set.predictable_items.each do |item|
          match = matches_by_id[item.predictable_id]
          predicted_score = yield(item)
          match.set_individual_team_scores(predicted_score)
          predicted_matches << match
        end
        @group.matches = predicted_matches
        GroupTableCalculator.new(@group).calculate
      end

      def save_predictions_for_group_matches
        matches_by_id = @group.matches_by_id
        existing_predictions_by_item_id = @user.predictions.by_predictable_item(@group_matches_set)
        new_predictions = (existing_predictions_by_item_id.nil? or existing_predictions_by_item_id.empty?)

        Core::Prediction.transaction do
          @group_matches_set.predictable_items.each do |item|
            match = matches_by_id[item.predictable_id]
            prediction = new_predictions ? Core::Prediction.new : existing_predictions_by_item_id[item.id].first
            prediction.core_user_id = @user.id if new_predictions
            prediction.configuration_predictable_item_id = item.id if new_predictions
            prediction.predicted_value = match.home_team_score + '-' + match.away_team_score
            prediction.save!
          end
        end
      end
    end
  end
end