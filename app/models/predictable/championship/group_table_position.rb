module Predictable
  module Championship
    class GroupTablePosition < ActiveRecord::Base
      include Comparable
      set_table_name("predictable_championship_group_table_positions")
      belongs_to :group, :class_name => "Predictable::Championship::Group", :foreign_key => "predictable_championship_group_id"
      belongs_to :team, :class_name => "Predictable::Championship::Team", :foreign_key => 'predictable_championship_team_id'

      # Accessors for accumulated match results, goal score and points
      attr_accessor :played, :won, :draw, :lost, :goals_for, :goals_against, :goal_diff, :pts
      # Boolean identicator whether the team has the same values for :pts, :goal_diff and :goals_for as at least one other team in the group
      attr_accessor :tied
      # Rank value of the tied team. For tied teams the one with the highest rank value has precedence
      attr_accessor :rank
      # The order in which the team will be displayed in the group table. If no criteria can distinguish two teams, they will be sorted alphabetically
      attr_accessor :display_order
      
      def after_initialize
        self.played, self.won, self.draw, self.lost, self.goals_for, self.goals_against, self.goal_diff, self.pts = 0, 0, 0, 0, 0, 0, 0, 0
        self.tied = false
        self.rank = 0
        self.display_order = self.pos
      end

      def <=> (other)
        if self.pts != other.pts
          return self.pts <=> other.pts
        elsif self.goal_diff != other.goal_diff
          return self.goal_diff <=> other.goal_diff
        elsif self.goals_for != other.goals_for
          return self.goals_for <=> other.goals_for
        elsif self.tied==true and other.tied==true and self.rank != other.rank
          return self.rank <=> other.rank
        else          
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

      # checks if the team is tied with another team, i.e., whether the points, goal diff and goals scored are identically
      def is_tied_with?(other)
        (self.pts == other.pts) and (self.goal_diff == other.goal_diff) and (self.goals_for == other.goals_for)
      end

      # adds the rank by adding the goals scored and subtract the goals conceeded
      def update_rank(goals_for, goals_against)
        self.rank += (goals_for - goals_against)
      end
    end
  end
end

