module Predictable
  module Championship
    class PredictionCollector
      include Ruleby

      def initialize(user=nil)
        @user = user
#        @summary = {:groups => {}, :stages => {}}
#        ('A'..'H').each {|group_name| @summary[:groups][group_name] = {:matches => [], :table => {}}}
#        ["Round of 16", "Quarter finals", "Semi finals", "Final"].each {|stage| @summary[:stages][stage] = {:teams => []}}
#        @summary[:stages]["Final"].merge(:winner_team => nil)
#        @summary[:stages]["Third Place"] = {:winner_team => nil}
      end

      # returns a prediction summary for the given user, a nested hash map with the following structure:
      # {:groups => {:a => {:matches => [Match1, Match2,..,Match6], :table => [Position1, ..., Position4]},
      #             {:b => {:matches => [Match1, Match2,..,Match6], :table => [Position1, ..., Position4]}},
      #             ...
      #  :stages => {:round-of-16 => {:teams => [Team1, Team2, .., Team8]}},...,
      #            {:final => {:teams => [Team1, Team2], :winner => Team2}},
      #            {:third-place => {:teams => [Team1, Team2], :winner => Team2}}
      #  }
      def get_all
        init_user_summary

        engine :prediction_collection do |e|
          rulebook = PredictionMapperRulebook.new(e)
          rulebook.summary = @summary
          rulebook.rules

          @user.predictions.each {|prediction| e.assert prediction}
          Configuration::PredictableItem.find(:all).each {|item| e.assert item}
          Predictable::Championship::Stage.find_by_description("Group").matches.each {|match| e.assert match}
          ["Final", "Third Place"].each {|match_descr| e.assert Predictable::Championship::Match.find_by_description(match_descr)}
          Predictable::Championship::GroupTablePosition.find(:all).each {|pos| e.assert pos}
          Predictable::Championship::Team.find(:all).each {|team| e.assert team}

          e.match          
        end
        @summary
      end

      # return a nested hash with the predictable item as key and the value an inner hash keyed by
      # participant name and with the predicted score as value
      def get_all_upcoming(participants)
        upcomming_matches = Predictable::Championship::Match.upcomming
        items_by_match_id = Predictable::Championship::PredictableItemsResolver.new(upcomming_matches).find_items
        collect_participant_predictions_for(upcomming_matches, items_by_match_id, participants)
      end

      def get_all_latest(participants)
        latest_matches = Predictable::Championship::Match.latest
        items_by_match_id = Predictable::Championship::PredictableItemsResolver.new(latest_matches, :processed).find_items
        collect_participant_predictions_for(latest_matches, items_by_match_id, participants)
      end

    private

      def init_user_summary
        @summary = {:groups => {}, :stages => {}}
        ('A'..'H').each {|group_name| @summary[:groups][group_name] = {:matches => [], :table => {}}}
        ["Round of 16", "Quarter finals", "Semi finals", "Final"].each {|stage| @summary[:stages][stage] = {:teams => []}}
        @summary[:stages]["Final"].merge(:winner_team => nil)
        @summary[:stages]["Third Place"] = {:winner_team => nil}
      end

      def collect_participant_predictions_for(matches, items_by_match_id, participants)
        participant_predictions_by_predictable = {}
        
        matches.each do |match|

          if match.is_group_match?
            participant_predictions_by_predictable[match] = participants_predictions_for_group_match(match, items_by_match_id, participants)
          else
            participant_predictions_by_predictable[match] = participants_predictions_for_knockout_stage_match(match, participants)
          end
        end

        participant_predictions_by_predictable
      end

      def participants_predictions_for_group_match(match, items_by_match_id, participants)
        item = items_by_match_id[match.id]
        predictions_by_participant_name = {}

        participants.each do |participant|
          prediction = participant.prediction_for(item)
          predictions_by_participant_name[participant.name] = prediction if prediction
        end
        predictions_by_participant_name
      end

      def participants_predictions_for_knockout_stage_match(match, participants)
        participant_names_by_team_name = {match.home_team.name => [], match.away_team.name => [], "none" => []}
        set = Configuration::Set.find_by_description("Teams through to " + match.stage.next.description)
        teams = [match.home_team, match.away_team]

        participants.each do |participant|
          predicted_teams = 0
          teams.each do |team|
            if participant.prediction_with_value(team.id.to_s, set)
              participant_names_by_team_name[team.name] << participant.name
              predicted_teams += 1
            end
          end

          if predicted_teams == 0
            participant_names_by_team_name["none"] << participant.name
          end
        end
        match.objectives = set.objectives
        participant_names_by_team_name
      end

      class PredictionMapperRulebook < Ruleby::Rulebook

        attr_accessor :summary

        def rules
          
          ("A".."H").each do |group_name|
             group_set = Configuration::Set.find_by_description("Group " + group_name + " Matches")

             rule :set_predicted_group_matches, {:priority => 4},
               [Configuration::PredictableItem, :group_match_item,
                 m.configuration_set_id == group_set.id,
                {m.predictable_id => :group_match_id, m.id => :group_match_item_id}],
               [Prediction, :prediction,
                 m.configuration_predictable_item_id == b(:group_match_item_id)],
               [Predictable::Championship::Match, :group_match,
                 m.id == b(:group_match_id)] do |v|

                 v[:group_match].score = v[:prediction].predicted_value
                 v[:group_match].objectives_meet = v[:prediction].objectives_meet if v[:group_match_item].processed?
                 @summary[:groups][group_name][:matches] << v[:group_match]
                 retract v[:group_match]
                 retract v[:prediction]
                 retract v[:group_match_item]              
            end

            table_set = Configuration::Set.find_by_description("Group " + group_name + " Table")
            rule :set_predicted_group_tables, {:priority => 3},
               [Configuration::PredictableItem, :table_position_item,
                 m.configuration_set_id == table_set.id,
                {m.predictable_id => :table_position_id, m.id => :table_position_item_id}],
               [Prediction, :prediction,
                 m.configuration_predictable_item_id == b(:table_position_item_id)],
               [Predictable::Championship::GroupTablePosition, :table_position,
                 m.id == b(:table_position_id)] do |v|

                 v[:table_position].objectives_meet = v[:prediction].objectives_meet if v[:table_position_item].processed?
                 @summary[:groups][group_name][:table][v[:prediction].predicted_value] = v[:table_position]
                 retract v[:table_position]
                 retract v[:prediction]
                 retract v[:table_position_item]
            end
          end

          ["Round of 16", "Quarter finals", "Semi finals", "Final"].each do |stage_descr|
            stage_set = Configuration::Set.find_by_description("Teams through to " + stage_descr)
            stage = Predictable::Championship::Stage.find_by_description(stage_descr)
            
            rule :set_predicted_stage_teams, {:priority => 2},
               [Configuration::PredictableItem, :stage_team_item,
                 m.configuration_set_id == stage_set.id,
                {m.id => :stage_team_item_id}],
               [Prediction, :prediction,
                 m.configuration_predictable_item_id == b(:stage_team_item_id),
                {m.predicted_value => :team_id}],
               [Predictable::Championship::Team, :team,
                 m.id(:team_id, &c{|id,tid| id.to_s.eql?(tid)})] do |v|

#                 if v[:stage_team_item].processed?
#                   v[:team].objectives_meet = v[:team].is_through_to_stage?(stage) ? 1 : 0
#                 end
                 v[:team].objectives_meet_for[stage.id] = v[:prediction].objectives_meet
#                 v[:team].objectives_meet = v[:prediction].objectives_meet
                 @summary[:stages][stage_descr][:teams] << v[:team]
                 retract v[:stage_team_item]
                 retract v[:prediction]
                 modify v[:team]
            end
          end

          {"Final" => "Winner Team", "Third Place" => "Third Place Team"}.each do |match_descr, set_descr|

            rule :resolve_match_winner, {:priority => 1},
               [Predictable::Championship::Match, :match,
                  m.description == match_descr,
                 {m.id => :match_id}],
               [Configuration::PredictableItem, :stage_team_item,
                  m.description == set_descr,
                  m.predictable_id == b(:match_id),
                 {m.id => :winner_item_id}],
               [Prediction, :winner_prediction,
                  m.configuration_predictable_item_id == b(:winner_item_id),
                 {m.predicted_value => :team_id}],
               [Predictable::Championship::Team, :team, m.id(:team_id, &c{|id,tid| id.to_s.eql?(tid)})] do |v|


                 v[:team].objectives_meet = v[:winner_prediction].objectives_meet
                 @summary[:stages][match_descr][:winner_team] = v[:team]
                 retract v[:match]
                 retract v[:stage_team_item]
                 retract v[:winner_prediction]
                 retract v[:team]
            end
          end
        end
      end
    end
  end
end