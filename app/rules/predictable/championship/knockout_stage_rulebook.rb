module Predictable
  module Championship
    class KnockoutStageRulebook < Ruleby::Rulebook

      ROUND_OF_16_RANKS = {"WA - RB" => 1, "WC - RD" => 2, "WE - RF" => 3, "WG - RH" => 4,
        "WB - RA" => 5, "WD - RC" => 6, "WF - RE" => 7, "WH - RG" => 8}

      def round_of_16_rules
#        puts "rules for round of 16"

        rule :resolve_group_winner, {:priority => 3},
             [Predictable::Championship::Group, :group, m.winner == nil,
               {m.id => :group_id}],
             [Predictable::Championship::Team, :team,
               {m.id => :team_id}],
             [Predictable::Championship::GroupTablePosition, :pos,
               m.predictable_championship_team_id == b(:team_id),
               m.predictable_championship_group_id == b(:group_id),
              {m.id => :pos_id}],
             [Configuration::PredictableItem, :item, m.predictable_id == b(:pos_id),
               {m.id => :item_id}],
             [Predictable::Championship::Prediction, :prediction, m.predicted_value == "1",
               m.item_id == b(:item_id)] do |v|

#          puts "Winner group " + v[:group].name + ": " + v[:team].name
          v[:group].winner = v[:team]
          retract v[:team]
        end

        rule :resolve_group_runnerup, {:priority => 2},
             [Predictable::Championship::Group, :group, m.runner_up == nil,
               {m.id => :group_id}],
             [Predictable::Championship::Team, :team,
               {m.id => :team_id}],
             [Predictable::Championship::GroupTablePosition, :pos,
               m.predictable_championship_team_id == b(:team_id),
               m.predictable_championship_group_id == b(:group_id),
              {m.id => :pos_id}],
             [Configuration::PredictableItem, :item, m.predictable_id == b(:pos_id),
               {m.id => :item_id}],
             [Predictable::Championship::Prediction, :prediction, m.predicted_value == "2",
               m.item_id == b(:item_id)] do |v|

#          puts "Runner up group " + v[:group].name + ": " + v[:team].name
          v[:group].runner_up = v[:team]
          modify v[:group]
          retract v[:team]
        end

        [["A","B"], ["C","D"], ["E","F"], ["G","H"]].each do |paired_groups|
          first_group, second_group = paired_groups[0], paired_groups[1]

          [[first_group, second_group], [second_group, first_group]].each do |pair|
            first, second = pair[0], pair[1]

            rule :resolve_match_teams, {:priority => 1},
                 [Predictable::Championship::Group, :group, m.name == first, m.winner.not == nil, m.runner_up.not == nil],
                 [Predictable::Championship::Group, :other_group, m.name == second, m.winner.not == nil, m.runner_up.not == nil],
                 [Predictable::Championship::Match, :match, m.description == match_description(first, second)] do |v|

              v[:match].home_team = v[:group].winner#(v[:match].description.eql?("W%{v[:group_name]} - R%{v[:other_group_name]}")) ? v[:group].winner : v[:other_group].winner
              v[:match].away_team = v[:other_group].runner_up#(v[:match].description.eql?("W%{v[:other_group_name]} - R%{v[:group_name]}")) ? v[:group].runner_up : v[:other_group].runner_up

              puts "Match: " + v[:match].description + ": " + v[:match].home_team.name + " - " + v[:match].away_team.name
              v[:match].rank = ROUND_OF_16_RANKS[v[:match].description]
              retract v[:match]
            end
          end
        end
      end

      private

      def match_description(first_group, second_group)
        "W"+first_group+" - "+"R"+second_group
      end

      def is_match_for_groups?(desc, group_name, other_group_name)
        desc.eql?("W%{group_name} - R%{other_group_name}") or desc.eql?("W%{other_group_name} - R%{group_name}")
      end
    end
  end
end
