module Predictable
  module Championship
    # Rulebook for setteling the scores for group matches, identifying tied teams
    # (i.e., teams with equal number of points, goal diff and goals scored), and
    # ranking such teams according to the given championship tie-break criteria
    # (http://en.wikipedia.org/wiki/FIFA_2010#Tie-breaking_criteria)
    class GroupTableRulebook < Ruleby::Rulebook

      def rules
        rule :settle_matches, {:priority => 3},
             [Predictable::Championship::Match, :group_match, m.state_name == :unsettled,
               {m.home_team_id => :home_team_id, m.away_team_id => :away_team_id}],
             [Predictable::Championship::GroupTablePosition, :home_team,
               m.predictable_championship_team_id == b(:home_team_id)],
             [Predictable::Championship::GroupTablePosition, :away_team,
               m.predictable_championship_team_id == b(:away_team_id)] do |v|

          unless v[:group_match].settled?
            v[:home_team].update_scores(v[:group_match].home_team_score.to_i, v[:group_match].away_team_score.to_i)
#            modify v[:home_team]
            v[:away_team].update_scores(v[:group_match].away_team_score.to_i, v[:group_match].home_team_score.to_i)
#            modify v[:away_team]
            v[:group_match].settle!
            modify v[:group_match]
          end
        end

        rule :identify_tied_teams, {:priority => 2},
             [Predictable::Championship::GroupTablePosition, :t1, m.tied==false,
               {m.id=>:id1, m.pts=>:pts, m.goals_for=>:gf, m.goal_diff=>:gd}],
             [Predictable::Championship::GroupTablePosition, :t2,
                #VM: m.id.not==b(:id1), m.pts==b(:pts), m.goal_diff==b(:gd), m.goals_for==b(:gf)] do |v|
                m.id.not==b(:id1), m.pts==b(:pts)] do |v|

            v[:t1].tied = true
            modify v[:t1]
            v[:t2].tied = true
            modify v[:t2]
        end

        rule :rank_tied_teams, {:priority => 1},
             [Predictable::Championship::Match, :group_match, m.state_name==:settled,
               {m.home_team_id => :home_team_id, m.away_team_id => :away_team_id}],
             [Predictable::Championship::GroupTablePosition, :home_team,
               m.tied==true, m.predictable_championship_team_id == b(:home_team_id)],
             [Predictable::Championship::GroupTablePosition, :away_team,
               m.tied==true, m.predictable_championship_team_id == b(:away_team_id)] do |v|
                        
            if v[:home_team].is_tied_with?(v[:away_team])
              v[:home_team].update_rank(v[:group_match].home_team_score.to_i, v[:group_match].away_team_score.to_i)
              v[:away_team].update_rank(v[:group_match].away_team_score.to_i, v[:group_match].home_team_score.to_i)
            end

            retract v[:group_match]
        end
      end
    end
  end
end