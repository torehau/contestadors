module Predictable
  module Championship
    class Stage < ActiveRecord::Base
      set_table_name("predictable_championship_stages")
      has_many :matches, :class_name => "Predictable::Championship::Stage"
      has_many :stage_teams, :class_name => "Predictable::Championship::StageTeam", :foreign_key => "predictable_championship_stage_id"
      has_many :teams, :through => :stage_teams, :class_name => "Predictable::Championship::Team"       
    end
  end
end
