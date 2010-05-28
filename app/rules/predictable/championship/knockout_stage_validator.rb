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
            rulebook.rules(stage.description)
            rulebook.errors = @errors

            e.assert stage
            e.assert summary

            set = Configuration::Set.find_by_description "Teams through to " + stage.description
            summary.user.predictions_for(set).each {|prediction| e.assert prediction}
            stage.matches.each {|match| e.assert match.winner}

            e.match
          end
        end
        @errors
      end

    private

      class KnockoutStageValidationRulebook < Ruleby::Rulebook

        attr_accessor :errors

        def rules(stage_description)

          {"h" => ["Quarter finals", "Semi finals", "Final"],
           "r" => ["Semi finals", "Final"],
           "q" => ["Final"]}.each do |current_state, stage_descriptions|

            stage_descriptions.each do |stage_descr|

              rule :invalid_stage_transitions, {:priority => 2},
                [Predictable::Championship::Stage, :stage, m.description == stage_descr],
                [PredictionSummary, :summary, m.state == current_state] do |v|

                   @errors[v[:stage].id] = "Not possible to predict the " + v[:stage].description + ". Predictions for previous knockout stages have been invalidated."
                 end
            end
          end


          rule :winner_teams_through_to_stage_being_predicted, {:priority => 1},
            [Predictable::Championship::Team, :team,
             {m.id => :winner_team_id}],
            [:not, Prediction, :stage_team_prediction, 
              m.predicted_value(:winner_team_id, &c{|pv, wtid| pv.eql?(wtid.to_s)})] do |v|

            @errors[:winner_team_id] = "Not possible to predict the " + stage_description + ". Teams selected as winners not predicted through to this stage."
            retract v[:team]
          end
        end
      end
    end
  end
end
