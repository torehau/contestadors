module Predictable
  module Championship

    # For validating that a stage might be predicted. It is possible to change the
    # state in another browser session so that the data has become inconsitant.
    class KnockoutStageValidator
      include Ruleby

      def initialize
        @errors = {}
      end

      def validate(stage, summary)
        if stage

          engine :knockout_stages do |e|
            rulebook = KnockoutStageValidationRulebook.new(e)
            rulebook.rules
            rulebook.errors = @errors

            e.assert stage
            e.assert summary

            e.match
          end
        end
        @errors
      end

    private

      class KnockoutStageValidationRulebook < Ruleby::Rulebook

        attr_accessor :errors

        def rules

          {"h" => ["Quarter finals", "Semi finals", "Final"],
           "r" => ["Semi finals", "Final"],
           "q" => ["Final"]}.each do |current_state, stage_descriptions|

            stage_descriptions.each do |stage_descr|

              rule :invalid_stage_transitions,
                [Predictable::Championship::Stage, :stage, m.description == stage_descr],
                [PredictionSummary, :summary, m.state == current_state] do |v|

                   @errors[v[:stage].id] = "Not possible to predict the " + v[:stage].description + ". Predictions for previous stages has been invalidated."
#                   retract v[:gm]
                 end
            end
          end
        end
      end
    end
  end
end
