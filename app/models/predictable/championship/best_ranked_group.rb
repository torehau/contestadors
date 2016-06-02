module Predictable
  module Championship
    class BestRankedGroup < ActiveRecord::Base
      set_table_name("predictable_championship_best_ranked_groups")
      has_many :qualifications, :class_name => "Predictable::Championship::ThirdPlaceGroupTeamQualification", :foreign_key => "predictable_championship_best_ranked_group_id"
    end
  end
end
