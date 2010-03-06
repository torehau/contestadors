module Predictable
  module Championship
    class Team < ActiveRecord::Base
      set_table_name("predictable_championship_teams")
      has_many :home_matches, :class_name => "Predictable::Championship::Match", :foreign_key => 'home_team_id'
      has_many :away_matches, :class_name => "Predictable::Championship::Match", :foreign_key => 'away_team_id'
      has_many :stage_teams, :class_name => "Predictable::Championship::StageTeam", :foreign_key => "predictable_championship_team_id"
      has_many :stages, :through => :stage_teams, :class_name => "Predictable::Championship::Stage"
      has_many :players, :class_name => "Predictable::Championship::Player", :foreign_key => "predictable_championship_team_id"
      has_one :group_table_position, :class_name => "Predictable::Championship::GroupTablePosition", :foreign_key => 'predictable_championship_team_id'

      attr_accessor :through_to_stage
      
      def after_initialize
        self.through_to_stage = []
      end

      def matches
        home_matches + away_matches
      end

      def is_through_to_next_stage?(current_stage)
        self.through_to_stage.include?(current_stage.next.id)
      end
    end
  end
end