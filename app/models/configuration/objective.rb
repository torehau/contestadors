module Configuration
  class Objective < ActiveRecord::Base
    set_table_name "configuration_objectives"
    belongs_to :category, :class_name => "Configuration::Category", :foreign_key => "configuration_category_id"
  end
end
