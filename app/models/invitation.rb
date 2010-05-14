class Invitation < ActiveRecord::Base
  belongs_to :contest_instance
  belongs_to :existing_user, :class_name => "User", :foreign_key => "existing_user_id"
  belongs_to :sender, :class_name => "User", :foreign_key => "sender_id"
  has_one :participation
  validates_presence_of :name, :email
  validates_email_format_of :email
  validates_uniqueness_of :email, :scope => :contest_instance_id
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

    event :send_invitation do
      transition :n => :s
    end

    event :accept_invitation do
      transition [:n, :s] => :a
    end
  end
end
