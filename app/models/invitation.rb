class Invitation < ActiveRecord::Base
  belongs_to :contest_instance
  belongs_to :existing_user, :class_name => "User", :foreign_key => "existing_user_id"
  belongs_to :sender, :class_name => "User", :foreign_key => "sender_id"
  has_one :participation
  validates_presence_of :name, :email
  validates_email_format_of :email
  validates_uniqueness_of :email, :scope => :contest_instance_id
  validate :email_different_from_invitor_email
  define_statistic :contest_invitations_count, :count => :all, :filter_on => { :state => 'state = ?', :contest_instance_id => 'contest_instance_id = ?'}

  STATE_DISPLAY_NAME_ID_BY_STATE_NAME             = {'n'  => 'New',
                                                     's'  => 'Sent',
                                                     'a'  => 'Accepted'}

  def before_create
    existing_user = User.find_by_email(self.email)
    if existing_user
      self.name = existing_user.name
      self.existing_user_id = existing_user.id
    end
    self.token = get_unique_token
  end

  def invited_on
    created_at
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

  def email_different_from_invitor_email
    if is_the_same_email?(self.sender.try(:email), self.email)
      errors.add(:email, "It is not allowed invite yourself as a contest member.")
    end
  end

  def is_the_same_email?(email_1, email_2)
    return false unless email_1 and email_2
    email_1.downcase.eql?(email_2.downcase)
  end

  def get_unique_token(timestamp = Time.now.to_f)
    seed = self.email + self.name + timestamp.to_s
    uuid = UUIDTools::UUID.sha1_create(UUIDTools::UUID_DNS_NAMESPACE, seed).to_s
    Invitation.exists?(:token => uuid) ? get_unique_token(timestamp + 1) : uuid
  end
end
