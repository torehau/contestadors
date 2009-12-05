module Configuration
  class IncludedSet < ActiveRecord::Base
    set_table_name "configuration_included_sets"
    belongs_to :contest, :class_name => "Configuration::Contest", :foreign_key => "configuration_contest_id"
    belongs_to :set, :class_name => "Configuration::Set", :foreign_key => "configuration_set_id"
  end
end
