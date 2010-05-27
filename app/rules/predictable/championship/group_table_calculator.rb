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
      def calculate(calculate_display_order)
        engine :group_table do |e|
          GroupTableRulebook.new(e).rules

          @group.matches.each{|group_match| e.assert group_match}
          @group.table_positions.each{|table_position| e.assert table_position}

          e.match
        end
#        set_sorted_positions(calculate_display_order)
        @group.sort_group_table(calculate_display_order)
        @group
      end

#      private
#
#      # Assigns position and display order accoring to the sorted group table positions
#      def set_sorted_positions(calculate_display_order)
#        pos, increment, display_order = 0, 1, 1
#        previous, current = nil, nil
#
#        @group.table_positions.sort!{|a, b| calculate_display_order ? (b <=> a) : (a.display_order <=> b.display_order)}.each do |table_position|
#          current = table_position
#
#          unless previous and previous.is_tied_with?(current) and previous.rank == current.rank
#            pos += increment
#            increment = 1
#          else
#            increment += 1
#            previous.can_move_down = true
#            current.can_move_up = true
#          end
#          table_position.pos = pos
#
#          if calculate_display_order
#            table_position.display_order = display_order
#            @group.winner = table_position.team if display_order == 1
#            @group.runner_up = table_position.team if display_order == 2
#            display_order += 1
#          end
#          previous = current
#        end
#        @group
#      end
    end
  end
end

