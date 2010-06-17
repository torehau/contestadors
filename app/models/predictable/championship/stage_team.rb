module Predictable
  module Championship
    class StageTeam < ActiveRecord::Base
      set_table_name("predictable_championship_stage_teams")
      belongs_to :stage, :class_name => "Predictable::Championship::Stage", :foreign_key => "predictable_championship_stage_id"
      belongs_to :team, :class_name => "Predictable::Championship::Team", :foreign_key => 'predictable_championship_team_id'
      belongs_to :match, :class_name => "Predictable::Championship::Match", :foreign_key => 'predictable_championship_match_id'
      has_one :stage_qualification, :class_name => "Predictable::Championship::StageQualification", :foreign_key => "predictable_championship_stage_team_id"

      def qualified_from_match
        return nil unless stage_qualification
        stage_qualification.match
      end

      def settle(team)
        self.team = team
        
        if self.is_home_team?
          self.match.home_team = team
        else
          self.match.away_team = team
        end
        self.match.save!
        self.save!
      end
    end
  end
end

