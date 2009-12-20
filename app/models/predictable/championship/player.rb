module Predictable
  module Championship
    class Player < ActiveRecord::Base
      set_table_name("predictable_championship_players")
      belongs_to :team, :class_name => "Predictable::Championship::Team", :foreign_key => 'predictable_championship_team_id'
    end
  end
end

