module Predictable
  module Championship
    class StageQualification < ActiveRecord::Base
      set_table_name("predictable_championship_stage_qualifications")
      belongs_to :match, :class_name => "Predictable::Championship::Match", :foreign_key => "predictable_championship_match_id"
      belongs_to :stage_team, :class_name => "Predictable::Championship::StageTeam", :foreign_key => "predictable_championship_stage_team_id"
    end
  end
end

