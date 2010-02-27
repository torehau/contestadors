module Predictable
  module Championship
    class StageRepository < Repository
      # TODO configure this on the set or somehthing
      PERCENTAGE_COMPLETED_FOR_STAGE = 5 

      def initialize(aggregate=nil)
        super(aggregate)
        @aggregate.all_roots = Stage.knockout_stages
        # TODO consider to reconfigure as stage team prediction ta having this stage specific aggregate instance variable:
        @aggregate.associated = Match.find_by_description("Third Place")
      end

      protected

      def get_aggregate_root(aggregate_root_id)
        aggregate_root_id ||="round-of-16"
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

      def validate(predicted_aggregate_root)
        # TODO should validation be performed in this case? Can input from radio buttons be manipulated?
        {}
      end

      def save_predictions_for_aggregate
        stage_teams_by_id = set_teams_for_next_stage
        @stage_teams_set = Configuration::Set.find_by_description "Teams through to #{@root.next.description}"
        save_predictions_for_stage(stage_teams_by_id)
        @user.prediction_summary.predict_stage(@root.description)        
        stage_from_existing_predictions
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

      def stage_from_existing_predictions        
        result = KnockoutStageResolver.new(@user).predicted_stages        
        @aggregate.all_predicted_roots = result[1]
        @root = result[0]
      end
    end
  end
end
