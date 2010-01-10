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
        engine :group_table do |e|
          rulebook = GroupTableRulebook.new(e)
          rulebook.settle_matches

          @group.matches.each{|group_match| e.assert group_match}
          @group.table_positions.each{|table_position| e.assert table_position}

          e.match

          rulebook.identify_tied_teams
          e.match

          rulebook.rank_tied_teams
          e.match
        end
        set_sorted_positions
      end

      private

      def set_sorted_positions
        sorted_positions = @group.table_positions.sort{|a, b| b <=> a}
        pos, increment = 0, 1
        pos_by_team_id = {}
        previous, current = nil, nil

        sorted_positions.each do |table_position|
          current = table_position

          unless previous and previous.has_same_score?(current) and previous.rank == current.rank
            pos += increment
            increment = 1
          else
            increment += 1
          end
          pos_by_team_id[table_position.predictable_championship_team_id] = pos
          previous = current
        end
        @group.table_positions.each { |tp| tp.pos = pos_by_team_id[tp.predictable_championship_team_id]}
        @group
      end
    end
  end
end

