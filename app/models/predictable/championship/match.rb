module Predictable
  module Championship
    class Match < ActiveRecord::Base
      include Comparable
      set_table_name("predictable_championship_matches")
      belongs_to :stage, :class_name => "Predictable::Championship::Stage", :foreign_key => "predictable_championship_stage_id"
      belongs_to :home_team, :class_name => "Predictable::Championship::Team", :foreign_key => 'home_team_id'
      belongs_to :away_team, :class_name => "Predictable::Championship::Team", :foreign_key => 'away_team_id'
      has_many :group_qualifications, :class_name => "Predictable::Championship::GroupQualification", :foreign_key => "predictable_championship_match_id"
      has_one :stage_qualifications, :class_name => "Predictable::Championship::StageQualification", :foreign_key => "predictable_championship_match_id"

      attr_accessor :home_team_score, :away_team_score, :state
      attr_accessor :rank
      attr_accessor :winner

      def after_initialize
        @score ||= "0-0"
        scores = @score.split("-")
        set_individual_team_scores(scores[0],scores[1])
        self.state = "unsettled"
        self.rank = self.id
      end

      def <=> (other)
        date_compare = self.play_date <=> other.play_date
        return date_compare unless date_compare == 0
        self.home_team.name <=> other.home_team.name
      end

      def winner_id
        self.winner ? self.winner.id : nil
      end

      def starts_at
        self.play_date
      end

      def ends_at
        self.play_date + 2.hours
      end

      def set_individual_team_scores(home_team_score, away_team_score)
        @home_team_score = home_team_score
        @away_team_score = away_team_score
      end

      def team_not_through_to_next_stage
        return self.home_team unless self.home_team.is_through_to_next_stage?(self.stage)
        self.away_team
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
