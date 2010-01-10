module Predictable
  module Championship
    class GroupTablePosition < ActiveRecord::Base
      include Comparable
      set_table_name("predictable_championship_group_table_positions")
      belongs_to :group, :class_name => "Predictable::Championship::Group", :foreign_key => "predictable_championship_group_id"
      belongs_to :team, :class_name => "Predictable::Championship::Team", :foreign_key => 'predictable_championship_team_id'

      attr_accessor :played, :won, :draw, :lost, :goals_for, :goals_against, :goal_diff, :pts, :tied, :rank
      
      def after_initialize
        self.played, self.won, self.draw, self.lost, self.goals_for, self.goals_against, self.goal_diff, self.pts = 0, 0, 0, 0, 0, 0, 0, 0
        self.tied = false
        self.rank = 0
      end
#
#      WIN, DRAW, LOST = 1, 0, -1

      # The group table shall be set up after the following criteria:
      #
      # 1. greatest number of points in all group matches;
      # 2. goal difference in all group matches;
      # 3. greatest number of goals scored in all group matches.
      # 4. greatest number of points in matches between tied teams;
      # 5. goal difference in matches between tied teams;
      # 6. greatest number of goals scored in matches between tied teams;
      # 7. drawing of lots by the FIFA Organising Committee or play-off depending on time schedule.
      def <=> (other)

        if self.pts != other.pts # 1
          return self.pts <=> other.pts
        elsif self.goal_diff != other.goal_diff # 2
          return self.goal_diff <=> other.goal_diff
        elsif self.goals_for != other.goals_for # 3
          return self.goals_for <=> other.goals_for
        elsif self.tied==true and other.tied==true and self.rank != other.rank
          return self.rank <=> other.rank
        else
          # TODO implementere regel 4-7 vha ruleby
          return -(self.team.name <=> other.team.name)
        end
      end

      #updates the table position for a match played, :won, :draw, :lost, :goals_for, :goals_against, :goal_diff, :pts
      def update_scores(gf, ga)
        self.played += 1

        if gf > ga
          self.won += 1
          self.pts += 3
        elsif gf == ga
          self.draw += 1
          self.pts += 1
        else
          self.lost += 1
        end
        self.goals_for += gf
        self.goals_against -= ga
        self.goal_diff += (gf - ga)
      end

      def has_same_score?(other)
        (self.pts == other.pts) and (self.goal_diff == other.goal_diff) and (self.goals_for == other.goals_for)
      end
    end
  end
end

