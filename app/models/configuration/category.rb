module Configuration
  class Category < ActiveRecord::Base
    set_table_name "configuration_categories"
    has_many :objectives, :class_name => "Configuration::Objective", :foreign_key => "configuration_category_id"

    attr_reader :predictable_items
    attr_reader :sets

    def after_initialize
      @sets = objectives.collect {|t| t.sets}.flatten.uniq
      @predictable_items = @sets.collect{|t| t.predictable_items}.flatten.uniq
    end
  end
end
