module Predictable
  module Championship
    class StageRepository < Repository
      PERCENTAGE_COMPLETED_FOR_STAGE = 5 # TODO configure this on the set or somehthing

      def initialize(user=nil, permalink="round-of-16")
        super(user)
        @stage = Stage.from_permalink permalink        
      end

      def get
        if @user
          return [stage_from_existing_predictions, true]
        end
        [@stage, false]
      end

      def save(predicted_stage)
        # TODO should validation be performed in this case? Can input from radio buttons be manipulated?
        @validation_errors = {}

        if @user and @validation_errors.empty?
          stage_teams_by_id = stage_from_new_predictions(predicted_stage)
          @stage_teams_set = Configuration::Set.find_by_description "Teams through to #{@stage.next.description}"
          save_predictions_for_stage(stage_teams_by_id)
          @user.prediction_summary.predict_stage(@stage.description)
        end

        return [stage_from_existing_predictions, @validation_errors, @new_predictions]
        rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid
          [stage_from_existing_predictions, @validation_errors, @new_predictions]
      end

      private

      def stage_from_new_predictions(params)
        predicted_winners_by_match_id = params[:predicted_matches]
        winners = {}
        predicted_winners_by_match_id.each do |match_id, match|
          winners[match_id.to_i] = Predictable::Championship::Team.find(match[:winner].to_i)
        end

        stage_teams_by_id = {}
        @stage.matches.each{|match| match.winner = winners[match.id]}

        @stage.next.stage_teams.each do |stage_team|
          match = stage_team.qualified_from_match
          stage_team.team = winners[match.id]
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
        [result[0], result[1]]
      end
    end
  end
end

