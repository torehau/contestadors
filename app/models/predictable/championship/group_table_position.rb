module Predictable
  module Championship
    class GroupTablePosition < ActiveRecord::Base
      set_table_name("predictable_championship_group_table_positions")
      belongs_to :group, :class_name => "Predictable::Championship::Group", :foreign_key => "predictable_championship_group_id"
      belongs_to :team, :class_name => "Predictable::Championship::Team", :foreign_key => 'predictable_championship_team_id'      
    end
  end
end

