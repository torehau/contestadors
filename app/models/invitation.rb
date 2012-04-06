class Invitation < ActiveRecord::Base
  before_create :existing_user_enrichment, :assign_unique_token
  belongs_to :contest_instance
  has_one :contest, :through => :contest_instance, :class_name => "Configuration::Contest"
  belongs_to :existing_user, :class_name => "User", :foreign_key => "existing_user_id"
  belongs_to :sender, :class_name => "User", :foreign_key => "sender_id"
  has_one :participation
  validates_presence_of :name, :email
  validates_email_format_of :email
  validates_uniqueness_of :email, :scope => :contest_instance_id
  validate :email_different_from_invitor_email, :no_dummy_values_provided
  define_statistic :contest_invitations_count, :count => :all, :filter_on => { :state => 'state = ?', :contest_instance_id => 'contest_instance_id = ?'}

  STATE_DISPLAY_NAME_ID_BY_STATE_NAME             = {'n'  => 'New',
                                                     's'  => 'Sent',
                                                     'a'  => 'Accepted'}
  DUMMY_EMAIL = "participant@email.com"
  DUMMY_NAME = "New Participant Name"

  def self.new_with_dummy_values
    Invitation.new(:name => DUMMY_NAME, :email => DUMMY_EMAIL)
  end

  def self.user_by_token(token)
    invitation = Invitation.find_by_token(token)

    if invitation

      if invitation.participation
        return invitation.participation.user
      else
        return invitation.existing_user
      end
    end
    nil
  end

  def invited_on
    created_at
  end

  def is_accepted?
    self.state.eql?("a")
  end

  def state_display_name
    STATE_DISPLAY_NAME_ID_BY_STATE_NAME[self.state]
  end

  def self.not_accepted_states
    ['n', 's']
  end

  def self.accepted_state
    ['a']
  end

  # stages :n - new, :s - sent, :a - accepted
  state_machine :initial => :n do

    event :deliver do
      transition :n => :s
    end

    event :accept do
      transition [:n, :s] => :a
    end
  end

  def self.sync_existing_invitations_for(user)
    if user
      Invitation.find(:all, :conditions => {:email => user.email, :state => ['n', 's']}).each do |invitation|
        invitation.existing_user_id = user.id
        invitation.save
      end
    end
  end

private

  def no_dummy_values_provided
    if self.email and self.email.downcase.eql?(DUMMY_EMAIL)
      errors.add(:email, "The provided email address is not valid.")
    end

    if self.name and self.name.downcase.eql?(DUMMY_NAME)
      errors.add(:name, "The provided name is not valid.")
    end
  end

  def email_different_from_invitor_email
    if is_the_same_email?(self.sender.try(:email), self.email)
      errors.add(:email, "It is not allowed to invite yourself as a contest member.")
    end
  end

  def is_the_same_email?(email_1, email_2)
    return false unless email_1 and email_2
    email_1.downcase.eql?(email_2.downcase)
  end

  def existing_user_enrichment
    existing_user = User.find_by_email(self.email)

    if existing_user
      self.name = existing_user.name
      self.existing_user_id = existing_user.id
    end
  end

  def assign_unique_token
    self.token = get_unique_token
  end

  def get_unique_token(timestamp = Time.now.to_f)
    seed = self.email + self.name + timestamp.to_s
    uuid = UUIDTools::UUID.sha1_create(UUIDTools::UUID_DNS_NAMESPACE, seed).to_s
    Invitation.exists?(:token => uuid) ? get_unique_token(timestamp + 1) : uuid
  end
end
