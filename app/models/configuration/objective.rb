module Configuration
  class Objective < ActiveRecord::Base
    set_table_name "configuration_objectives"
    belongs_to :category, :class_name => "Configuration::Category", :foreign_key => "configuration_category_id"
    has_many :included_objectives, :class_name => "Configuration::IncludedObjective", :foreign_key => "configuration_objective_id"
    has_many :sets, :through => :included_objectives

    def predictable_items
      items = []
      sets.each{|set| set.predictable_items.collect{|pi| items << pi}}
      items
    end
  end
end
