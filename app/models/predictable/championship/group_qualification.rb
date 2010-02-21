module Predictable
  module Championship
    class GroupQualification < ActiveRecord::Base
      set_table_name("predictable_championship_group_qualifications")
      belongs_to :group, :class_name => "Predictable::Championship::Group", :foreign_key => "predictable_championship_group_id"
      belongs_to :match, :class_name => "Predictable::Championship::Match", :foreign_key => "predictable_championship_match_id"
    end
  end
end
