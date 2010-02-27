module Predictable
  module Championship
    class Stage < ActiveRecord::Base
      # TODO use permalink_fu plugin
      set_table_name("predictable_championship_stages")
      has_many :matches, :class_name => "Predictable::Championship::Match", :foreign_key => "predictable_championship_stage_id"
      has_many :stage_teams, :class_name => "Predictable::Championship::StageTeam", :foreign_key => "predictable_championship_stage_id"
      has_many :teams, :through => :stage_teams, :class_name => "Predictable::Championship::Team"
      belongs_to :next, :class_name => "Predictable::Championship::Stage", :foreign_key => "next_stage_id"

      named_scope :knockout_stages, :conditions => {:description => ["Round of 16", "Quarter-finals", "Semi-finals", "Final"]}, :order => "id DESC"
      named_scope :explicit_predicted_knockout_stages, :conditions => {:description => ["Quarter-finals", "Semi-finals", "Final"]}, :order => "id DESC"

      def self.from_permalink(permalink)
        description = ""

        if (permalink.eql?("round-of-16"))
          description = "Round of 16"
        end
        Stage.find_by_description(description)
      end

      def permalink
        description.downcase.sub(' ', '-')
      end
    end
  end
end
