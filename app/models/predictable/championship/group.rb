module Predictable
  module Championship
    class Group < ActiveRecord::Base
      set_table_name("predictable_championship_groups")
      has_many :table_positions, :class_name => "Predictable::Championship::GroupTablePosition", :foreign_key => "predictable_championship_group_id"
      has_many :teams, :through => :table_positions, :class_name => "Predictable::Championship::Team"

      attr_accessor :matches
      attr_accessor :winner, :runner_up

      def after_initialize
        @matches = teams.collect {|t| t.matches}.flatten.uniq.sort
        @winner, @runner_up = nil, nil
      end

      # Returns a hash with the matches keyed by the id
      def matches_by_id
        Hash[*matches.collect{|match| [match.id, match]}.flatten]
      end

      # Returnes true if the group table contains tied teams with the same rank
      def is_rearrangable?
        table_positions.each {|position| return true if (position.can_move_up == true) or (position.can_move_down == true)}
        return false
      end
    end
  end
end

