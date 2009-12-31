module Predictable
  module Championship
    class Group < ActiveRecord::Base
      set_table_name("predictable_championship_groups")
      has_many :table_positions, :class_name => "Predictable::Championship::GroupTablePosition", :foreign_key => "predictable_championship_group_id"
      has_many :teams, :through => :table_positions, :class_name => "Predictable::Championship::Team"

      def matches
        teams.collect {|t| t.matches}.flatten.uniq.sort
      end
    end
  end
end

