module Predictable
  module Championship
      class GroupTableRulebook < Ruleby::Rulebook

      def settle_matches
        rule :settle_matches, #{:priority => 2},
             [Predictable::Championship::Match, :group_match, m.state_name==:unsettled,
               {m.home_team_id => :home_team_id, m.away_team_id => :away_team_id}],
             [Predictable::Championship::GroupTablePosition, :home_team,
               m.predictable_championship_team_id == b(:home_team_id)],
             [Predictable::Championship::GroupTablePosition, :away_team,
               m.predictable_championship_team_id == b(:away_team_id)] do |v|

          v[:home_team].update_scores(v[:group_match].home_team_score.to_i, v[:group_match].away_team_score.to_i)
          v[:away_team].update_scores(v[:group_match].away_team_score.to_i, v[:group_match].home_team_score.to_i)
          v[:group_match].settle!
        end
      end

      def identify_tied_teams
        rule :identify_tied_teams,# {:priority => 2},
             [Predictable::Championship::GroupTablePosition, :t1, m.tied==false,
               {m.id=>:id1, m.pts=>:pts, m.goals_for=>:gf, m.goal_diff=>:gd}],
             [Predictable::Championship::GroupTablePosition, :t2,
               m.id.not==b(:id1), m.pts==b(:pts), m.goal_diff==b(:gd), m.goals_for==b(:gf)] do |v|

            v[:t1].tied = true
            v[:t2].tied = true
        end
      end

      def rank_tied_teams
        rule :rank_tied_teams,# {:priority => 1},
             [Predictable::Championship::Match, :group_match, m.state_name==:settled,
               {m.home_team_id => :home_team_id, m.away_team_id => :away_team_id}],
             [Predictable::Championship::GroupTablePosition, :home_team,
               m.tied==true, m.predictable_championship_team_id == b(:home_team_id)],
             [Predictable::Championship::GroupTablePosition, :away_team,
               m.tied==true, m.predictable_championship_team_id == b(:away_team_id)] do |v|

            v[:group_match].mark_as_tied!
            retract v[:group_match]
            
            if v[:home_team].has_same_score?(v[:away_team])
              v[:home_team].rank += (v[:group_match].home_team_score.to_i - v[:group_match].away_team_score.to_i)
              v[:away_team].rank += (v[:group_match].away_team_score.to_i - v[:group_match].home_team_score.to_i)
            end
        end
      end
    end
  end
end