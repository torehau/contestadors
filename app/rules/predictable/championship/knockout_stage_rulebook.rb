module Predictable
  module Championship
    class KnockoutStageRulebook < Ruleby::Rulebook

      def rules(predicted_stages)
        rule :resolve_match_home_teams, {:priority => 2},
           [Predictable::Championship::Stage, :stage,
             {m.id => :stage_id}],
           [Predictable::Championship::Match, :match,
              m.predictable_championship_stage_id == b(:stage_id),
              m.home_team == nil,
             {m.id => :match_id}],
           [Predictable::Championship::StageTeam, :stage_team,
              m.predictable_championship_stage_id == b(:stage_id),
              m.predictable_championship_match_id == b(:match_id),
              m.is_home_team == true,
             {m.id => :stage_team_id}],
           [Configuration::PredictableItem, :stage_team_item,
              m.predictable_id == b(:stage_team_id),
             {m.id => :stage_team_item_id}],
           [Prediction::Base, :stage_team_prediction,
              m.configuration_predictable_item_id == b(:stage_team_item_id),
             {m.predicted_value => :team_id}],
           [Predictable::Championship::Team, :team, m.id(:team_id, &c{|id,tid| id.to_s.eql?(tid)})] do |v|

          v[:team].through_to_stage << v[:stage].id
          v[:match].home_team = v[:team]
          puts "Match: " + v[:match].description + ": " + v[:match].home_team.name

          retract v[:stage_team]
          retract v[:stage_team_item]
          retract v[:stage_team_prediction]
          modify v[:match]
        end

        rule :resolve_match_away_teams, {:priority => 1},
           [Predictable::Championship::Stage, :stage,
             {m.id => :stage_id}],
           [Predictable::Championship::Match, :match,
              m.predictable_championship_stage_id == b(:stage_id),
              m.home_team.not == nil,
              m.away_team == nil,
             {m.id => :match_id}],
           [Predictable::Championship::StageTeam, :stage_team,
              m.predictable_championship_stage_id == b(:stage_id),
              m.predictable_championship_match_id == b(:match_id),
              m.is_home_team == false,
             {m.id => :stage_team_id}],
           [Configuration::PredictableItem, :stage_team_item,
              m.predictable_id == b(:stage_team_id),
             {m.id => :stage_team_item_id}],
           [Prediction::Base, :stage_team_prediction,
              m.configuration_predictable_item_id == b(:stage_team_item_id),
             {m.predicted_value => :team_id}],
           [Predictable::Championship::Team, :team, m.id(:team_id, &c{|id,tid| id.to_s.eql?(tid)})] do |v|

          v[:team].through_to_stage << v[:stage].id
          v[:match].away_team = v[:team]

          puts "Match: " + v[:match].description + ": " + v[:match].home_team.name + " - " + v[:match].away_team.name
          retract v[:stage_team]
          retract v[:stage_team_item]
          retract v[:stage_team_prediction]
          retract v[:match]

          predicted_stages[v[:stage].id] = v[:stage] unless predicted_stages.include?(v[:stage])
        end
      end
    end
  end
end
