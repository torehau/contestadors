module Predictable
  module Championship
    class StageTeam < ActiveRecord::Base
      set_table_name("predictable_championship_stage_teams")
      belongs_to :stage, :class_name => "Predictable::Championship::Stage", :foreign_key => "predictable_championship_stage_id"
      belongs_to :team, :class_name => "Predictable::Championship::Team", :foreign_key => 'predictable_championship_team_id'      
    end
  end
end

