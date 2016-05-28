module Predictable
  module Championship
    class GroupTablePosition < ActiveRecord::Base
      include Comparable, Predictable::Handler
      set_table_name("predictable_championship_group_table_positions")
      after_initialize :init_stats
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
      # Indicating whether the match score for this team is identical with the team at the display order above and below
      attr_accessor :can_move_down, :can_move_up

=begin vm
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
=end

      def <=> (other)
        if self.pts != other.pts
          return self.pts <=> other.pts
        elsif self.tied==true and other.tied==true and self.rank != other.rank
          return self.rank <=> other.rank
        elsif self.goal_diff != other.goal_diff
          return self.goal_diff <=> other.goal_diff
        elsif self.goals_for != other.goals_for
          return self.goals_for <=> other.goals_for
        else
          return -(self.team.ranking_coefficient <=> other.team.ranking_coefficient)
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
        self.goals_against += ga
        self.goal_diff += (gf - ga)
      end

      # checks if the team is tied with another team, i.e., whether the points, goal diff and goals scored are identically
      def is_tied_with?(other)
        #vm: (self.pts == other.pts) and (self.goal_diff == other.goal_diff) and (self.goals_for == other.goals_for)
        self.pts == other.pts
      end

      # adds the rank by adding the goals scored and subtract the goals conceeded
      def update_rank(goals_for, goals_against)
        self.rank += (goals_for - goals_against)
      end

      # TODO should be moved to Handler module
      def settle(position)
        self.pos = position.to_i
                
        if self.pos == 1
          self.group.winner_stage_team.settle(self.team)
        elsif self.pos == 2
          self.group.runner_up_stage_team.settle(self.team)
        end
        self.save!
      end

      def resolve_objectives_for(prediction, objectives)
        predicted_pos = prediction.predicted_value
        return {:objectives_meet => objectives, :objectives_missed => []} if self.pos.to_s.eql?(predicted_pos)
        {:objectives_meet => [], :objectives_missed => objectives}
      end

  private

      def init_stats
        self.played, self.won, self.draw, self.lost, self.goals_for, self.goals_against, self.goal_diff, self.pts = 0, 0, 0, 0, 0, 0, 0, 0
        self.tied = false
        self.rank = 0
        self.display_order = self.pos
        self.can_move_down, self.can_move_up = false, false
      end
    end
  end
end

