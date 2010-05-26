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
  has_many :administered_contest_instances, :class_name => "ContestInstance", :foreign_key => "admin_user_id" do
    def for_contest(contest)
      find(:all, :conditions => {:configuration_contest_id => contest.id}, :order => "name")
    end
    def for_contest_instance(contest_instance)
      find(:first, :conditions => {:id => contest_instance.id})
    end
  end
  has_many :invitations, :class_name => "Invitation", :foreign_key => "existing_user_id" do
    def not_accepted
      find(:all, :conditions => {:state => ['New', 'Sent']})
    end
  end
  has_many :sent_invitations, :class_name => "Invitation", :foreign_key => "sender_id"
  has_many :participations do
    def as_participant(contest)
      find(:all, :joins => [:contest_instance],
           :conditions => ["contest_instances.configuration_contest_id = :contest_id", {:contest_id => contest.id}],
           :order => "contest_instances.name")
    end
    def as_member(contest)
      find(:all, :joins => [:invitation, :contest_instance],
           :conditions => ["contest_instances.configuration_contest_id = :contest_id", {:contest_id => contest.id}],
           :order => "contest_instances.name")
    end
    def of(contest_instance)
      find(:first, :conditions => ["participations.contest_instance_id = :contest_instance_id and participations.invitation_id is not null", {:contest_instance_id => contest_instance.id}])
    end
  end
  has_many :score_table_positions

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

  def instances_of(contest, role)
    contest ||= Configuration::Contest.find(:first)
    role ||= :all
    case role
    when :admin then admin_contests_instances(contest)
    when :member then member_contests_instances(contest)
    when :all then participant_contests_instances(contest)
    end
  end


  def default_contest
    administered_contest = self.administered_contest_instances.first
    return administered_contest if administered_contest
    participation = self.participations.first
    participation ? participation.contest_instance : nil
  end

  def is_participant_of?(contest_instance)
    return false unless contest_instance
    (is_admin_of?(contest_instance) or is_member_in?(contest_instance))
  end

  def is_admin_of?(contest_instance)
    not self.administered_contest_instances.for_contest_instance(contest_instance).nil?
  end

  def is_member_in?(contest_instance)
    not self.participations.of(contest_instance).nil?
  end

  def admin_contests_instances(contest)
    self.administered_contest_instances.for_contest(contest)
  end

  def member_contests_instances(contest)
    self.participations.as_member(contest).collect{|participation| participation.contest_instance}
  end

  def participant_contests_instances(contest)
    self.participations.as_participant(contest).collect{|participation| participation.contest_instance}
  end

  def deliver_password_reset_instructions!
    reset_perishable_token!
    Notifier.deliver_password_reset_instructions(self)
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
