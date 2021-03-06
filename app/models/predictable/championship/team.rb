module Predictable
  module Championship
    class Team < ActiveRecord::Base
      set_table_name("predictable_championship_teams")
      after_initialize :init_metrics
      has_many :home_matches, :class_name => "Predictable::Championship::Match", :foreign_key => 'home_team_id'
      has_many :away_matches, :class_name => "Predictable::Championship::Match", :foreign_key => 'away_team_id'
      has_many :stage_teams, :class_name => "Predictable::Championship::StageTeam", :foreign_key => "predictable_championship_team_id" do
        def through_to(stage)
          find(:first, :conditions => {:predictable_championship_team_id => self.id, :predictable_championship_stage_id => stage.id})
        end
      end
      has_many :stages, :through => :stage_teams, :class_name => "Predictable::Championship::Stage"
      has_many :players, :class_name => "Predictable::Championship::Player", :foreign_key => "predictable_championship_team_id"
      has_one :group_table_position, :class_name => "Predictable::Championship::GroupTablePosition", :foreign_key => 'predictable_championship_team_id'

      attr_accessor :through_to_stage
      attr_accessor :objectives_meet, :objectives_meet_for

      def matches
        home_matches + away_matches
      end

      def group_matches
        group_stage = Predictable::Championship::Stage.where(:description => "Group").last
        matches.select{|match| match.stage.id == group_stage.id}
      end

      def is_through_to_stage?(stage)
        self.stage_teams.through_to(stage)
      end

      def is_through_to_next_stage?(current_stage)
        current_stage.next and self.through_to_stage.include?(current_stage.next.id)
      end

    private

      def init_metrics
        self.through_to_stage = []
        self.objectives_meet_for = {}
      end
    end
  end
end
