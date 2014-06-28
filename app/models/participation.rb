class Participation < ActiveRecord::Base
  after_create :accept_invitation
  belongs_to :user
  belongs_to :contest_instance
  belongs_to :invitation
  has_one :score_table_position
  validates_presence_of :user_id, :contest_instance_id
  validates_uniqueness_of :user_id, :scope => :contest_instance_id
  define_statistic :participants_count, :count => :all, :filter_on => {:active => 'active = ?', :contest_instance_id => 'contest_instance_id = ?'}

  def prediction_state_name(contest)
    summary = user.summary_of(contest)
    summary ? summary.state : "i"
  end

  def is_admin?
    user.is_admin_of?(contest_instance)
  end
  
  def send_email_notification_for?(comment)
    !user.nil? and !user.email.nil? and !user.email.nil? and user.id != comment.user.id and user.email_notifications_on_comments?
  end

private

  def accept_invitation
    if self.invitation
      self.invitation.accept!
    end
  end
end
