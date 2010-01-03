module Core
  class User < ActiveRecord::Base
    set_table_name("core_users")
    acts_as_authentic
    has_many :predictions, :class_name => "Core::Prediction", :foreign_key => "core_user_id" do
      def by_predictable_item(set)
        find(:all, :conditions => {:configuration_predictable_item_id => set.predictable_items.collect{|pi| pi.id}}).group_by(&:configuration_predictable_item_id)
      end
    end
  end
end
