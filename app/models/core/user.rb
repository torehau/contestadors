module Core
  class User < ActiveRecord::Base
    set_table_name("core_users")
    acts_as_authentic
    has_many :predictions, :class_name => "Core::Prediction", :foreign_key => "core_user_id" do
      def for_set(set)
        find(:all, :conditions => {:configuration_predictable_item_id => set.predictable_items.collect{|pi| pi.id}})
      end
      def for_item(item)
        find(:first, :conditions => {:configuration_predictable_item_id => item.id})
      end
      def by_predictable_item(set)
        for_set(set).group_by(&:configuration_predictable_item_id)
      end
      def with_value_in_set(predicted_value, set)
        find(:first, :conditions => {:predicted_value => predicted_value,
                                     :configuration_predictable_item_id => set.predictable_items.collect{|pi| pi.id}})
      end
    end

    def predictions_for(set)
      predictions.for_set(set)
    end

    def prediction_for(item)
      predictions.for_item(item)
    end

    def prediction_with_value(value, in_set)
      predictions.with_value_in_set(value, in_set)
    end

    def predictions_by_item_id(set)
      predictions.by_predictable_item(set)
    end
  end
end
