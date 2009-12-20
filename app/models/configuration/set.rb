module Configuration
  class Set < ActiveRecord::Base
    set_table_name "configuration_sets"
    has_many :included_objectives, :class_name => "Configuration::IncludedObjective", :foreign_key => "configuration_set_id"
    has_many :objectives, :through => :included_objectives, :class_name => "Configuration::Objective"

    def predictable_type
      objectives.first.category.predictable_type
    end
  end
end
