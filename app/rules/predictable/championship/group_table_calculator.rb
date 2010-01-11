module Predictable
  module Championship
    # Calculates the group table according to the following rules:
    #
    #  1. greatest number of points in all group matches;
    #  2. goal difference in all group matches;
    #  3. greatest number of goals scored in all group matches.
    #  4. greatest number of points in matches between tied teams;
    #  5. goal difference in matches between tied teams;
    #  6. greatest number of goals scored in matches between tied teams;
    #  7. drawing of lots by the FIFA Organising Committee or play-off depending on time schedule.
    #
    # (from http://en.wikipedia.org/wiki/FIFA_2010#Tie-breaking_criteria)
    class GroupTableCalculator
      include Ruleby

      def initialize(group)
        @group = group
      end

      # Settles group match scores, idendifies tied teams and attempts to rank these temas
      # using the Ruleby rules
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

      # Assigns position and display order accoring to the sorted group table positions
      def set_sorted_positions
        pos, increment, display_order = 0, 1, 1
        previous, current = nil, nil

        @group.table_positions.sort!{|a, b| b <=> a}.each do |table_position|
          current = table_position

          unless previous and previous.is_tied_with?(current) and previous.rank == current.rank
            pos += increment
            increment = 1
          else
            increment += 1
          end
          table_position.pos = pos
          table_position.display_order = display_order
          display_order += 1
          previous = current
        end
        @group
      end
    end
  end
end

