module Configuration
  class Set < ActiveRecord::Base
    set_table_name "configuration_sets"
    belongs_to :prediction_state, :class_name => "Configuration::PredictionState", :foreign_key => 'configuration_prediction_state_id'
    has_many :predictable_items, :class_name => "Configuration::PredictableItem", :foreign_key => "configuration_set_id" do
      def by_predictable_id
        find(:all).group_by(&:predictable_id)
      end
      def for_predictable(predictable_id)
        find(:first, :conditions => {:predictable_id => predictable_id})
      end
      def for_predictables(predictable_ids)
        find(:all, :conditions => {:predictable_id => predictable_ids})
      end
    end
    has_many :included_objectives, :class_name => "Configuration::IncludedObjective", :foreign_key => "configuration_set_id"
    has_many :objectives, :through => :included_objectives, :class_name => "Configuration::Objective"

    def predictable_type
      objectives.first.category.predictable_type
    end

    def predictable_item(predictable_id)
      predictable_items.for_predictable(predictable_id)
    end

    def subset(predictable_ids)
      predictable_items.for_predictables(predictable_ids)
    end
  end
end
