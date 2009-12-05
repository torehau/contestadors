module Configuration
  class IncludedObjective < ActiveRecord::Base
    set_table_name "configuration_included_objectives"
    belongs_to :objective, :class_name => "Configuration::Objective", :foreign_key => "configuration_objective_id"
    belongs_to :set, :class_name => "Configuration::Set", :foreign_key => "configuration_set_id"
  end
end
