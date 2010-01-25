module Predictable
  module Championship
    class StageRepository

      def initialize(user=nil, permalink="round-of-16")
        @user = user
        @stage = Stage.from_permalink permalink
        @predictable_set = Configuration::Set.find_by_description "Teams through to #{@stage.description}"
      end

      def get
        if @user
          return [stage_from_existing_predictions, true]
        end
        [@stage, false]
      end

      private

      def stage_from_existing_predictions
        category = Configuration::Category.find_by_description "Group Tables"
        resolver = KnockoutStageResolver.new(@user.predictions_of(category), category.predictable_items)
        
        if @stage.description.eql?("Round of 16")
          @stage = resolver.round_of_16_matches
        end
        @stage
      end
    end
  end
end

