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

      # Settles group match scores, identifies tied teams and attempts to rank these teams
      # using the Ruleby rules
      def calculate(calculate_display_order)
        engine :group_table do |e|
          GroupTableRulebook.new(e).rules

          @group.matches.each{|group_match| e.assert group_match}
          @group.table_positions.each{|table_position| e.assert table_position}

          e.match
        end

        @group.sort_group_table(calculate_display_order)
        @group
      end
    end
  end
end

