module Predictable
  module Championship
    class ThirdPlaceGroupTeamQualification < ActiveRecord::Base
      set_table_name("predictable_championship_third_place_group_team_qualifications")
      belongs_to :best_ranked_group, :class_name => "Predictable::Championship::BestRankedGroup", :foreign_key => "predictable_championship_best_ranked_group_id"
      belongs_to :group, :class_name => "Predictable::Championship::Group", :foreign_key => "predictable_championship_group_id"
      belongs_to :stage_team, :class_name => "Predictable::Championship::StageTeam", :foreign_key => "predictable_championship_stage_team_id"
    end
  end
end
