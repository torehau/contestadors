module Predictable
  module Championship
    class Match < ActiveRecord::Base
      include Comparable
      set_table_name("predictable_championship_matches")
      belongs_to :stage, :class_name => "Predictable::Championship::Stage", :foreign_key => "predictable_championship_stage_id"
      belongs_to :home_team, :class_name => "Predictable::Championship::Team", :foreign_key => 'home_team_id'
      belongs_to :away_team, :class_name => "Predictable::Championship::Team", :foreign_key => 'away_team_id'

      attr_accessor :home_team_score, :away_team_score, :state
      attr_accessor :rank

      def after_initialize
        @score ||= "0-0"
        set_individual_team_scores(@score)
        self.state = "unsettled"
        self.rank = 0
      end

      def <=> (other)
        date_compare = self.play_date <=> other.play_date
        return date_compare unless date_compare == 0
        self.home_team.name <=> other.home_team.name
      end


      def set_individual_team_scores(score)
        scores = score.split('-')
        
        if scores and scores.length == 2
          @home_team_score = scores[0]
          @away_team_score = scores[1]
        end
      end

      state_machine :initial => :unsettled do

        event :settle do
          transition :unsettled => :settled
        end

        event :mark_as_tied do
          transition :settled => :tied
        end

        event :solve do
          transition :tied => :solved
        end

      end
    end
  end
end
