class User < ActiveRecord::Base
  acts_as_authentic
  has_many :prediction_summaries do#, :class_name => "Prediction::Summary", :foreign_key => "user_id", :dependent => :destroy do
    def for_contest(contest)
      find(:first, :conditions => {:configuration_contest_id => contest.id})
    end
  end
  has_many :predictions do#, :class_name => "Prediction", :foreign_key => "user_id" do
    def for_item(item)
      find(:first, :conditions => {:configuration_predictable_item_id => item.id})
    end
    def for_items(items)
      find(:all, :conditions => {:configuration_predictable_item_id => items})
    end
    def for_items_by_item_id(items)
      for_items(items).group_by(&:configuration_predictable_item_id)
    end
    def for_items_by_value(items)
      for_items(items).group_by(&:predicted_value)
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

  def summary_of(contest)
    prediction_summaries.for_contest(contest)
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
    add_prediction_summary_for_available_contests
  end

  def add_prediction_summary_for_available_contests
    Configuration::Contest.all_available.each do |contest|
      summary = PredictionSummary.new
      summary.user = self
      summary.contest = contest
      summary.save!
    end
  end
end
