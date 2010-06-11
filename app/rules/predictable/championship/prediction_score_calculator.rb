module Predictable
  module Championship
    class PredictionScoreCalculator
      include Ruleby

      def initialize(predictable, predictable_item)
        @predictable = predictable
        @predictable_item = predictable_item
      end

      def update_prediction_scores_for_group_matches
        engine :update_prediction_score do |e|
          rulebook = PredictionScoreRulebook.new(e)
#          rulebook.summary = @summary
          rulebook.group_matches_rules

          e.assert @predictable
          @predictable_item.predictions{|prediction| e.assert prediction}
          @predictable_item.set.objectives{|objective| e.assert objective}

          e.match
        end
      end

    private

      class PredictionScoreRulebook < Ruleby::Rulebook

        def group_matches_rules
          rule :group_matches, #{:priority => 3},
            [Predictable::Championship::Match, :group_match,
              m.score.not == nil,
              m.result.not == nil],
            [Configuration::Objective, :score_objective,
              m.predictable_field == "score"],
            [Configuration::Objective, :result_objective,
              m.predictable_field == "result"],
            [Prediction, :prediction] do |v|

               v[:prediction].set_score_for(v[:group_match], [v[:score_objective], v[:result_objective]])
               retract v[:prediction]
          end
        end
      end
    end
  end
end
