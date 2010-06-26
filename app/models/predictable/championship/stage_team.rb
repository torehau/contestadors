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

      # TODO move declearation to Handler module
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

      # TODO move declearation to Handler module, or preferably the item should
      # fetch this dynamically using the Configuration::Objective (predictable_field)
      def predictable_field_value
        return nil unless self.team
        self.team.id.to_s
      end

      # TODO move default implementation (return empty array) to Handler module
      # OBS OBS TODO DB fix must be done for stage_qualifications table
      def dependant_predictables(dependants=[])
        return dependants if self.stage.description.eql?("Final")
        next_stage_team = self.match.stage_qualifications.for_winner.stage_team
        dependants << next_stage_team
        next_stage_team.dependant_predictables(dependants)
      end

      def self.stage_teams_after(stage)
        following_stages = []
        next_stage = stage.is_final_stage? ? nil : stage.next

        while next_stage do
          following_stages << next_stage
          next_stage = next_stage.is_final_stage? ? nil : next_stage.next
        end

        following_stages.collect {|s| s.stage_teams}.flatten
      end
    end
  end
end

