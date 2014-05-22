class User < ActiveRecord::Base
  after_create :add_prediction_summary_for_available_contests
  acts_as_authentic do |c|
    # enable Authlogic_RPX account merging (false by default, if this statement is not present)
    c.account_merge_enabled true

    # set Authlogic_RPX account mapping mode
    c.account_mapping_mode :internal
  end
  has_many :identity_providers
  has_many :prediction_summaries do#, :class_name => "Prediction::Summary", :foreign_key => "user_id", :dependent => :destroy do
    def for_contest(contest)
      where(:configuration_contest_id => contest.id).first
      ##summary ||= add_summary(contest)
      #find(:first, :conditions => {:configuration_contest_id => contest.id})
    end
  end
  has_many :predictions do#, :class_name => "Prediction", :foreign_key => "user_id" do
    def for_item(item)
      where(:configuration_predictable_item_id => item.id).first
      #find(:first, :conditions => {:configuration_predictable_item_id => item.id})
    end
    def for_items(items)
      where(:configuration_predictable_item_id => items).all
      #find(:all, :conditions => {:configuration_predictable_item_id => items})
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
      where(:configuration_predictable_item_id => category.predictable_items.collect{|pi| pi.id}).all
      #find(:all, :conditions => {:configuration_predictable_item_id => category.predictable_items.collect{|pi| pi.id}})
    end
    def with_value_in_set(predicted_value, set)
      where(:predicted_value => predicted_value,:configuration_predictable_item_id => set.predictable_items.collect{|pi| pi.id}).first
      #find(:first, :conditions => {:predicted_value => predicted_value,
      #                             :configuration_predictable_item_id => set.predictable_items.collect{|pi| pi.id}})
    end
    def with_values_of_category(predicted_values, category)
      find(:all, :conditions => {:predicted_value => predicted_values,
                                 :configuration_predictable_item_id => category.predictable_items.collect{|pi| pi.id}})
    end
  end
  has_many :administered_contest_instances, :class_name => "ContestInstance", :foreign_key => "admin_user_id" do
    def for_contest(contest)
      where(:configuration_contest_id => contest.id).order("name").all
    end
    def for_contest_instance(contest_instance)
      find(:first, :conditions => {:id => contest_instance.id})
    end
    def except(contest)
      where("configuration_contest_id != ?", contest.id).all
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
      find(:all, :joins => [:contest_instance],
           :conditions => ["contest_instances.configuration_contest_id = :contest_id and participations.user_id != contest_instances.admin_user_id", {:contest_id => contest.id}],
           :order => "contest_instances.name")
    end
    def of(contest_instance)
      find(:first, :joins => [:contest_instance],
           :conditions => ["participations.contest_instance_id = :contest_instance_id and participations.user_id != contest_instances.admin_user_id", {:contest_instance_id => contest_instance.id}])
    end
  end
  has_many :score_table_positions

  def included_identity_providers
    return nil if self.identity_providers == nil or self.identity_providers.count == 0
    self.identity_providers.order(:provider_name).collect{|provider| provider.provider_name}
  end
  
  def has_participated_in_previous_contests?
    self.prediction_summaries.count > 1
  end
  
  def participating_in_tournaments
    tournament_ids = self.prediction_summaries.collect {|ps| ps.configuration_contest_id}.flatten.uniq
    Configuration::Contest.where("id in (:ids)", :ids => tournament_ids)
  end

  def summary_of(contest)
    prediction_summaries.for_contest(contest)
  end

  def add_summary(contest)
    summary = PredictionSummary.new
    summary.user = self
    summary.contest = contest
    summary.save!
    summary
  end

  def next_available_prediction_state(contest)
    summary = self.summary_of(contest)
    summary ||= add_summary(contest)
    prediction_state = contest.prediction_state(summary.state)
    next_prediction_state = prediction_state.next
    (next_prediction_state ? next_prediction_state : prediction_state)
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

  def winner_prediction_for(contest)
    set = contest.set("Winner Team")
    predictions = predictions_for(set)
    predictions and predictions.count == 1 ? Predictable::Championship::Team.find(predictions.first.predicted_value.to_i) : nil
  end

  def instances_of(contest, role)
    contest ||= Configuration::Contest.last
    role ||= :all
    case role
    when :admin then admin_contests_instances(contest)
    when :member then member_contests_instances(contest)
    when :all then participant_contests_instances(contest)
    end
  end

  def default_contest
    current_tournament = Configuration::Contest.last
    administered_contest = self.administered_contest_instances.for_contest(current_tournament).first
    return administered_contest if administered_contest
    participation = self.participations.as_participant(current_tournament).first
    participation ? participation.contest_instance : nil
  end

  def is_participant_of?(contest_instance)
    return false unless contest_instance
    (is_admin_of?(contest_instance) or is_member_in?(contest_instance))
  end

  def is_admin_of?(contest_instance)
    return false unless contest_instance
    not self.administered_contest_instances.for_contest_instance(contest_instance).nil?
  end

  def is_member_in?(contest_instance)
    return false unless contest_instance
    not self.participations.of(contest_instance).nil?
  end

  def admin_contests_instances(contest)
    self.administered_contest_instances.for_contest(contest)
  end

  def previously_administered_contests(contest)
    self.administered_contest_instances.except(contest)
  end

  def member_contests_instances(contest)
    self.participations.as_member(contest).collect{|participation| participation.contest_instance}
  end

  def participant_contests_instances(contest)
    self.participations.as_participant(contest).collect{|participation| participation.contest_instance}
  end

  def deliver_password_reset_instructions!
    reset_perishable_token!
    Notifier.password_reset_instructions(self).deliver
  end

	# before_merge_rpx_data provides a hook for application developers to perform data migration prior to the merging of user accounts.
	# This method is called just before authlogic_rpx merges the user registration for 'from_user' into 'to_user'
	# Authlogic_RPX is responsible for merging registration data.
	#
	# By default, it does not merge any other details (e.g. application data ownership)
	#
	def before_merge_rpx_data( from_user, to_user )
    User.transaction do

      # transfer all invitations sent by from_user to to_user, except where where the invitations were sent to to_user
      from_user.sent_invitations.each do |sent_invitation|
        unless sent_invitation.existing_user_id.eql?(to_user.id)
          sent_invitation.sender_id = to_user.id
          sent_invitation.save!
        end
      end

      # transfer all invitations received by from_user to to_user, except where the invitations where sent by to_user
      from_user.invitations.each do |invitation|
        unless invitation.sender_id.eql?(to_user.id)
          invitation.existing_user_id = to_user.id
          invitation.save!
        end
      end

      # transfer all participations for from_user to to_user, except where to_user already has a participation
      from_user.participations.each do |participation|
        unless to_user.is_participant_of?(participation.contest_instance)
          participation.user_id = to_user.id
          participation.save!
        end
      end

      # transfer all score_table_positions for from_user to to_user, except where to_user already has a participation/score_table_position
      from_user.score_table_positions.each do |position|
        unless to_user.is_participant_of?(position.contest_instance)
          position.user_id = to_user.id
          position.prediction_summary_id = to_user.prediction_summaries.last.id
          position.save!
        end
      end

      # transfer administrated contests, i.e, contests created by from_user, to to_user
      from_user.administered_contest_instances.each do |contest_instance|
        contest_instance.admin_user_id = to_user.id
        contest_instance.save!
      end
    end
	end

	# after_merge_rpx_data provides a hook for application developers to perform account clean-up after authlogic_rpx has
	# migrated registration details.
	#
	# By default, does nothing. It could, for example, be used to delete or disable the 'from_user' account
	#
	def after_merge_rpx_data( from_user, to_user )
    User.transaction do
      from_user.predictions.each{|prediction| prediction.destroy}
      from_user.prediction_summaries.each{|summary| summary.destroy}
      from_user.sent_invitations.each{|sent_invitation| sent_invitation.destroy}
      from_user.invitations.each{|invitation| invitation.destroy}
      from_user.participations.each{|participation| participation.destroy}
      from_user.score_table_positions.each{|score_table_position| score_table_position.destroy}
      from_user.destroy
    end
	end

protected

  def add_prediction_summary_for_available_contests
    Configuration::Contest.all_available.each {|contest| add_summary(contest)}
  end
end
