module Core
  class User < ActiveRecord::Base
    set_table_name("core_users")
    acts_as_authentic
    has_one :prediction_summary, :class_name => "Prediction::Summary", :foreign_key => "core_user_id", :dependent => :destroy
    has_many :predictions, :class_name => "Prediction::Base", :foreign_key => "core_user_id" do
      def for_item(item)
        find(:first, :conditions => {:configuration_predictable_item_id => item.id})
      end
      def for_items(items)
        find(:all, :conditions => {:configuration_predictable_item_id => items})
      end
      def for_items_by_item_id(items)
        for_items(items).group_by(&:configuration_predictable_item_id)
      end
      def for_set(set)
        for_items(set.predictable_items.collect{|pi| pi.id})
      end
      def by_predictable_item(set)
        for_set(set).group_by(&:configuration_predictable_item_id)
      end
      def for_category(category)
        find(:all, :conditions => {:configuration_predictable_item_id => category.predictable_items.collect{|pi| pi.id}})
      end
      def with_value_in_set(predicted_value, set)
        find(:first, :conditions => {:predicted_value => predicted_value,
                                     :configuration_predictable_item_id => set.predictable_items.collect{|pi| pi.id}})
      end
      def with_values_of_category(predicted_values, category)
        find(:all, :conditions => {:predicted_value => predicted_values,
                                   :configuration_predictable_item_id => category.predictable_items.collect{|pi| pi.id}})
      end
    end

    def predictions_for(set)
      predictions.for_set(set)
    end

    def predictions_for_subset(items)
      predictions.for_items(items)
    end

    def predictions_of(category)
      predictions.for_category(category)
    end

    def predictions_completed_for?(category)
      category.predictable_items.size == predictions_of(category).size
    end

    def prediction_for(item)
      predictions.for_item(item)
    end

    def prediction_with_value(value, in_set)
      predictions.with_value_in_set(value, in_set)
    end

    def predictions_with_values(values, category)
      predictions.with_values_of_category(values, category)
    end

    def predictions_by_item_id(set)
      predictions.by_predictable_item(set)
    end

    protected

    def after_create
      self.build_prediction_summary
      self.prediction_summary.save!
    end
  end
end
