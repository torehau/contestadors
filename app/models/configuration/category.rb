module Configuration
  class Category < ActiveRecord::Base
    set_table_name "configuration_categories"
    has_many :objectives, :class_name => "Configuration::Objective", :foreign_key => "configuration_category_id"
  end
end
