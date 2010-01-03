require 'ruleby'

# To change this template, choose Tools | Templates
# and open the template in the editor.
module Predictable
  module Championship
    class GroupTableCalculator
      include Ruleby

      def initialize(group)
        @group = group
      end

      def calculate
        engine :engine do |e|
          GroupTableRulebook.new e do |r|
            r.rules
          end
          @group.matches.each{|match| e.assert match}
          @group.table_positions.each{|table_position| e.assert table_position}
          e.match
        end        
        set_sorted_positions
      end

      private

      def set_sorted_positions
        sorted_positions = @group.table_positions.sort{|a, b| a <=> b}
        pos = 4
        pos_by_team_id = {}
        sorted_positions.each do |table_position|
          pos_by_team_id[table_position.predictable_championship_team_id] = pos
          pos -= 1
        end
        @group.table_positions.each { |tp| tp.pos = pos_by_team_id[tp.predictable_championship_team_id]}
        @group
      end

      class GroupTableRulebook < Ruleby::Rulebook
        WIN = 1
        DRAW = 0
        LOST = -1

        def rules
          rule [Predictable::Championship::Match, :match,{m.home_team_id => :home_team_id, m.home_team_score => :home_team_score,
                               m.away_team_id => :away_team_id, m.away_team_score => :away_team_score}],
               [Predictable::Championship::GroupTablePosition, :home_team, m.predictable_championship_team_id == b(:home_team_id)],
               [Predictable::Championship::GroupTablePosition, :away_team, m.predictable_championship_team_id == b(:away_team_id)] do |v|

            if (v[:home_team_score].to_i > v[:away_team_score].to_i)
              update_team_stats_for_match(v[:home_team],WIN,v[:home_team_score].to_i, v[:away_team_score].to_i)
              update_team_stats_for_match(v[:away_team],LOST,v[:away_team_score].to_i, v[:home_team_score].to_i)
            elsif (v[:home_team_score].to_i < v[:away_team_score].to_i)
              update_team_stats_for_match(v[:home_team],LOST,v[:home_team_score].to_i, v[:away_team_score].to_i)
              update_team_stats_for_match(v[:away_team],WIN,v[:away_team_score].to_i, v[:home_team_score].to_i)
            else
              update_team_stats_for_match(v[:home_team],DRAW,v[:home_team_score].to_i, v[:away_team_score].to_i)
              update_team_stats_for_match(v[:away_team],DRAW,v[:away_team_score].to_i, v[:home_team_score].to_i)
            end

            retract v[:match]
          end
        end
        
        private

        #updates the table position for a match played, :won, :draw, :lost, :goals_for, :goals_against, :goal_diff, :pts
        def update_team_stats_for_match(table_position,outcome,goals_for,goals_against)          
          table_position.played += 1

          if outcome == WIN
            table_position.won += 1
            table_position.pts += 3
          elsif outcome == DRAW
            table_position.draw += 1
            table_position.pts += 1
          else
            table_position.lost += 1
          end
          table_position.goals_for += goals_for
          table_position.goals_against -= goals_against
          table_position.goal_diff += (goals_for - goals_against)
        end
      end
    end
  end
end

