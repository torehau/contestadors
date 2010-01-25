module Predictable
  module Championship
    class Stage < ActiveRecord::Base
      set_table_name("predictable_championship_stages")
      has_many :matches, :class_name => "Predictable::Championship::Match", :foreign_key => "predictable_championship_stage_id"
      has_many :stage_teams, :class_name => "Predictable::Championship::StageTeam", :foreign_key => "predictable_championship_stage_id"
      has_many :teams, :through => :stage_teams, :class_name => "Predictable::Championship::Team"

      def self.from_permalink(permalink)
        description = ""

        if (permalink.eql?("round-of-16"))
          description = "Round of 16"
        end

        Stage.find_by_description(description)
      end
    end
  end
end
