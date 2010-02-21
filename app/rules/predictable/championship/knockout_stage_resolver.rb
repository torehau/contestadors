module Predictable
  module Championship

    class KnockoutStageResolver
      include Ruleby

      def initialize(user)
        @user = user
      end

      def predicted_stages
        @@category ||= Configuration::Category.find_by_description("Stage Teams")
        @predictable_items = @@category.predictable_items
        @predictions = @user.predictions_of(@@category).compact        
        @stages = Predictable::Championship::Stage.knockout_stages
        @teams = Predictable::Championship::Team.find(:all)
        @predicted_stages = {}

        engine :predicted_stage_matches do |e|
          KnockoutStageRulebook.new(e).rules(@predicted_stages)

          @teams.each {|team| e.assert team}
          @stages.each do |stage|
            stage.matches.each {|stage_match| e.assert stage_match}
            stage.stage_teams.each {|stage_team| e.assert stage_team}
            e.assert stage
          end
          
          @predictions.each{|prediction| e.assert prediction}
          @predictable_items.each{|item| e.assert item}

          e.match
        end
        [last_predicted_stage, @predicted_stages]
      end

      private

      def last_predicted_stage

        for stage in @predicted_stages.values
          unless @predicted_stages.values.include?(stage.next)
            # FIXED
            puts "**** returning stage: " + stage.description
            return stage
          end
        end
        @predicted_stages.values.first
      end
    end
  end
end
