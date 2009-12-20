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
    end
  end
end