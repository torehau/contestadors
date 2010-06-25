module Predictable
  module Championship
    class Match < ActiveRecord::Base
      include Comparable, Predictable::Handler
      set_table_name("predictable_championship_matches")
      belongs_to :stage, :class_name => "Predictable::Championship::Stage", :foreign_key => "predictable_championship_stage_id"
      belongs_to :home_team, :class_name => "Predictable::Championship::Team", :foreign_key => 'home_team_id'
      belongs_to :away_team, :class_name => "Predictable::Championship::Team", :foreign_key => 'away_team_id'
      has_many :group_qualifications, :class_name => "Predictable::Championship::GroupQualification", :foreign_key => "predictable_championship_match_id"
      has_many :stage_qualifications, :class_name => "Predictable::Championship::StageQualification", :foreign_key => "predictable_championship_match_id" do
        def for_winner
          find(:first, :conditions => {:is_winner => true})
        end
      end


      named_scope :upcomming, :conditions => ["score is null and result is null and play_date > ? ", Time.now - 2.hours], :order => "play_date ASC", :limit => 2
      named_scope :latest, :conditions => ["score is not null and result is not null"], :order => "play_date DESC", :limit => 2

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

      def is_group_match?
        "Group".eql?(self.stage.description)
      end

      def is_final?
        "Final".eql?(self.description)
      end

      def set_individual_team_scores(home_team_score, away_team_score)
        @home_team_score = home_team_score
        @away_team_score = away_team_score
      end

      def team_not_through_to_next_stage
        return self.home_team unless self.home_team.is_through_to_next_stage?(self.stage)
        self.away_team
      end

      def winner_stage_team
        self.stage_qualifications.for_winner.stage_team
      end

      def winner_team
        winner_team_from(self.result)
      end

      def losing_team
        losing_team_from(self.result)
      end

      def following_stage_teams
        following_stages = []
        next_stage = self.is_final? ? nil : self.stage.next

        while next_stage do
          following_stages << next_stage
          next_stage = next_stage.is_final_stage? ? nil : next_stage.next
        end

        following_stages.collect {|stage| stage.stage_teams}.flatten
      end

      def settle_match(score)
        result = result_from(score)
        self.update_attributes(:score => score, :result => result)
        self.save!
        unless self.is_group_match?
          winner_team = winner_team_from(result)
          stage_team = winner_stage_team
          stage_team.predictable_championship_team_id = winner_team.id
          stage_team.save!
        end
      end

      def resolve_objectives_for(prediction, objectives)
        predicted_score = prediction.predicted_value
        return {:objectives_meet => objectives, :objectives_missed => []} if self.score.eql?(predicted_score)
        result = {:objectives_meet => [], :objectives_missed => []}

        objectives.each do |objective|
          
          if ("score".eql?(objective.predictable_field))
            result[:objectives_missed] << objective
          else
            outcome = is_same_result?(String.new(predicted_score)) ? :objectives_meet : :objectives_missed
            result[outcome] << objective
          end
        end
        result
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

    private

      RESULT_BY_COMPARE_RESULT = {0 => "x", 1 => "1", -1 => "2"}

      def result_from(score)
        team_scores = score.split('-')
        RESULT_BY_COMPARE_RESULT[team_scores[0].to_i <=> team_scores[1].to_i]
      end
      
      def is_same_result?(predicted_score)
        self.result.eql?(result_from(predicted_score))
      end

      def winner_team_from(result)
        if "1".eql?(result)
          self.home_team
        elsif "2".eql?(result)
          self.away_team
        else
          nil
        end
      end

      def losing_team_from(result)
        if "1".eql?(result)
          self.away_team
        elsif "2".eql?(result)
          self.home_team
        else
          nil
        end
      end
    end
  end
end
