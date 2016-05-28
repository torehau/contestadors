module Predictable
  module Championship

    # For validating that a stage might be predicted. It is possible to change the
    # state in another browser session so that the data has become inconsitant.
    class KnockoutStageValidator
      include Ruleby

      def initialize(contest)
        @contest = contest
        @first_knockout_stage = ContestFirstKnockOutStageResolver.new.resolve(contest)
        @errors = {}
      end

      def validate(stage, summary)
        if stage

          engine :knockout_stages do |e|
            rulebook = KnockoutStageValidationRulebook.new(e)
            rulebook.rules(stage.description, @first_knockout_stage)
            rulebook.errors = @errors

            e.assert stage
            e.assert summary

            set = @contest.set("Teams through to " + stage.description)
            summary.user.predictions_for(set).each {|prediction| e.assert prediction}
            stage.matches.each do |match|
              e.assert match.winner
              e.assert match

              #if stage.description.eql?("Final")
              #  stage.next.matches.each{|match| e.assert match}
              #end
            end
            
            if stage.description.eql?(@first_knockout_stage.description)#("Round of 16")
              group_ids = @contest.unique_aggregate_root_ids("group")
              Predictable::Championship::Group.find(group_ids).each do |group|
                group.qualifications.each {|qualification| e.assert qualification}
                group.table_positions.each {|table_position| e.assert table_position}
              end
              items = CommonContestCategoryItemsResolver.new.resolve(@contest, "Group Tables")
              #summary.user.predictions_for_subset(items).each {|prediction| e.assert prediction}
              items.each do |item|
                e.assert item
                e.assert summary.user.prediction_for(item)
              end
              #category = Configuration::Category.find_by_description("Group Tables")
              #summary.user.predictions_of(category).each {|prediction| e.assert prediction}
              #category.predictable_items.each {|item| e.assert item}
            end

            e.match
          end
        end
        @errors
      end

    private

      class KnockoutStageValidationRulebook < Ruleby::Rulebook

        attr_accessor :errors

        def rules(stage_description, first_knockout_stage)

          # Illegal state transitions, Euro:
          #{"d" => ["Semi finals", "Final"],
           #"q" => ["Final"]
          {"f" => ["Quarter finals", "Semi finals", "Final"],
           "r" => ["Semi finals", "Final"],
           "q" => ["Final"]}.each do |current_state, stage_descriptions|

            stage_descriptions.each do |stage_descr|

              rule :invalid_stage_transitions, {:priority => 4},
                [Predictable::Championship::Stage, :stage, m.description == stage_descr],
                [PredictionSummary, :summary, m.state == current_state] do |v|

                   @errors[v[:stage].id] = "Not possible to predict the " + v[:stage].description + ". Predictions for previous knockout stages have been invalidated."
                 end
            end
          end

          rule :winner_teams_not_through_to_stage_being_predicted, {:priority => 3},
            [Predictable::Championship::Stage, :stage,
             {m.id => :stage_id, m.description => :stage_descr}],
            [Predictable::Championship::Match, :match,
              m.predictable_championship_stage_id == b(:stage_id),
              m.winner_id.not == nil,
             {m.id => :match_id, m.winner_id => :winner_team_id}],
            [:not, Prediction, :stage_team_prediction,
              m.description(:stage_descr, &c{|d, sd| d.eql?("Teams through to " + sd)}),
              m.predicted_value(:winner_team_id, &c{|pv, wtid| pv.eql?(wtid.to_s)})] do |v|

            @errors[:winner_team_id] = "Not possible to predict the " + stage_description + ". Teams selected as winners not predicted through to this stage."
            retract v[:match]
          end

          rule :first_knockout_stage_match_winner_teams_not_qualified_from_correct_group, {:priority => 2},
            [Predictable::Championship::Stage, :stage,
              m.description == first_knockout_stage.description,
             {m.id => :stage_id}],
            [Predictable::Championship::Match, :match,
              m.predictable_championship_stage_id == b(:stage_id),
              m.winner_id.not == nil,
             {m.id => :match_id, m.winner_id => :winner_id}],
            [Predictable::Championship::GroupQualification, :qualification,
              m.predictable_championship_match_id == b(:match_id),
             {m.group_pos => :group_pos, m.predictable_championship_group_id => :group_id}],
            [Predictable::Championship::GroupTablePosition, :group_table_position,
              m.predictable_championship_group_id == b(:group_id),
              m.predictable_championship_team_id == b(:winner_id),
             {m.id => :position_id}],
            [Configuration::PredictableItem, :group_table_position_item,
              m.predictable_id == b(:position_id),
             {m.id => :position_item_id}],
            [:not, Prediction, :group_table_position_prediction,
              m.configuration_predictable_item_id == b(:position_item_id),
              m.predicted_value(:group_pos, &c{|pv, gpos| pv.eql?(gpos.to_s)})] do |v|

            @errors[:match_id] = "Not possible to predict the " + stage_description + ". Teams selected as winners of matches not predicted to."
            retract v[:match]
          end

          # WC specific rule
          #rule :third_place_winner_team_not_predicted_to_final, {:priority => 1},
          #  [Predictable::Championship::Match, :match,
          #    m.description == "Third Place",
          #    m.winner_id.not == nil,
          #   {m.id => :match_id, m.winner_id => :winner_team_id}],
          #  [Prediction, :final_team_prediction,
          #    m.description == "Teams through to Final",
          #    m.predicted_value(:winner_team_id, &c{|pv, wtid| pv.eql?(wtid.to_s)})] do |v|

          #  @errors[:match_id] = "Not possible to predict the given team as winner of the Third Place Play-off match, when predicted through to the Final."
          #  retract v[:match]
          #end
        end
      end
    end
  end
end
