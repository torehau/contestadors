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
          @predictions.each{|prediction| e.assert Predictable::Championship::Prediction.new(prediction)}
          @predictable_items.each{|item| e.assert item}
          
          e.match
        end
        @stage
      end
    end

    class Prediction
      attr_accessor :predicted_value, :item_id

      def initialize(core_prediction)
        @predicted_value = core_prediction.predicted_value
        @item_id = core_prediction.configuration_predictable_item_id
      end
    end
  end
end
