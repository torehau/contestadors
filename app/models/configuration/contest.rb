module Configuration
  class Contest < ActiveRecord::Base
    set_table_name "configuration_contests"    
    has_many :included_sets, :class_name => "Configuration::IncludedSet", :foreign_key => "configuration_contest_id"
    has_many :sets, :through => :included_sets, :class_name => "Configuration::Set"    
  end
end
