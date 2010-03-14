module Predictable
  module Championship
    class StageRepository < Repository
      # TODO configure this on the set or somehthing
      PERCENTAGE_COMPLETED_FOR_STAGE = 7

      def initialize(aggregate=nil)
        super(aggregate)
        @aggregate.all_roots = Stage.knockout_stages
        # TODO consider to reconfigure as stage team prediction ta having this stage specific aggregate instance variable:
        @aggregate.associated = Match.find_by_description("Third Place")
      end

      protected

      def get_aggregate_root(aggregate_root_id)
        aggregate_root_id ||="round-of-16"
        aggregate_root_id = "final" if aggregate_root_id.eql?("completed")
        Stage.from_permalink(aggregate_root_id)        
      end

      def get_predictable_set
        Configuration::Set.find_by_description "Teams through to #{@root.description}"
      end

      def build_aggregate_root_from_existing_predictions
        stage_from_existing_predictions
      end

      def build_aggregate_root_from_new_predictions
        stage_from_new_predictions(@aggregate.new_predictions)        
      end

      # no validation should be necessary, since matches in the knockout stages is predicted
      # using radion buttons, which by default checks the home team if no predictions already exists
      def validate(predicted_aggregate_root)
        {}
      end

      def save_predictions_for_aggregate                
        unless @root.description.eql?("Final")
          stage_teams_by_id = set_teams_for_next_stage
          @stage_teams_set = Configuration::Set.find_by_description "Teams through to #{@root.next.description}"
          save_predictions_for_stage(stage_teams_by_id)
          @summary.predict_stage(@root.description)
          @aggregate.root = @root.next
        else
          save_final_and_third_place_play_off_winners
        end
        @aggregate
      end

      private

      def stage_from_new_predictions(predicted_winners_by_match_id)
        @winners = {}
        predicted_winners_by_match_id.each do |match_id, match|
          @winners[match_id.to_i] = Predictable::Championship::Team.find(match[:winner].to_i)
        end        
        @root.matches.each{|match| match.winner = @winners[match.id]}
        @root
      end

      def set_teams_for_next_stage
        stage_teams_by_id = {}
        @root.next.stage_teams.each do |stage_team|
          match = stage_team.qualified_from_match
          stage_team.team = @winners[match.id]
          stage_teams_by_id[stage_team.id] = stage_team
        end
        stage_teams_by_id
      end

      # saves the predicted stage teams for the current user.
      def save_predictions_for_stage(stage_teams_by_id)
        Prediction::Base.transaction do
          save_predictions(@stage_teams_set.predictable_items, stage_teams_by_id) do |stage_team|
            stage_team.team.id.to_s
          end
          update_prediction_progress(PERCENTAGE_COMPLETED_FOR_STAGE)
        end
      end

      def save_final_and_third_place_play_off_winners
        Prediction::Base.transaction do
          save_match_winner(Match.find_by_description("Final"), "Winner Team", @root.description)
          save_match_winner(@aggregate.associated, "Third Place Team", "Third Place")
        end
      end

      def save_match_winner(match, set_descr, stage_descr)
        winner = @winners[match.id]
        winner_set = Configuration::Set.find_by_description set_descr
        predictable_items = winner_set.predictable_items
        existing_predictions_by_item_id = @user.predictions.for_items_by_item_id(predictable_items)
        @new_predictions = (existing_predictions_by_item_id.nil? or existing_predictions_by_item_id.empty?)
        item = predictable_items.first
        prediction = @new_predictions ? Prediction::Base.new : existing_predictions_by_item_id[item.id].first
        save_predicted_value(prediction, @new_predictions, item, winner.id.to_s)
        update_prediction_progress(PERCENTAGE_COMPLETED_FOR_STAGE)
        @summary.predict_stage(stage_descr)
      end

      def stage_from_existing_predictions        
        @aggregate = KnockoutStageResolver.new(@aggregate).predicted_stages
        @aggregate.root
      end
    end
  end
end
