module Predictable
  module Championship

    class KnockoutStageResolver
      include Ruleby

      def initialize(predictions, predictable_items)
        @predictions = predictions
        @predictable_items = predictable_items
      end

      # resolves the predicted teams to the matches in the Round of 16 stage
      def round_of_16_matches
        @stage = Predictable::Championship::Stage.find_by_description("Round of 16")

        engine :group_table do |e|
          KnockoutStageRulebook.new(e).round_of_16_rules

          @stage.matches.each{|stage_match| e.assert stage_match}
          Predictable::Championship::Group.find(:all).each{|group| e.assert group}
          Predictable::Championship::GroupTablePosition.find(:all).each{|pos| e.assert pos}
          Predictable::Championship::Team.find(:all).each{|team| e.assert team}
          @predictions.each{|prediction| e.assert prediction}
          @predictable_items.each{|item| e.assert item}
          
          e.match
        end
        @stage
      end
    end
  end
end
