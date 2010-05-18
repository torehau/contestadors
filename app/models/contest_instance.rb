class ContestInstance < ActiveRecord::Base
  belongs_to :contest, :class_name => "Configuration::Contest", :foreign_key => "configuration_contest_id"
  belongs_to :admin, :class_name => "User", :foreign_key => "admin_user_id"
  has_many :invitations
  has_many :participations
  validates_presence_of :name, :admin_user_id, :configuration_contest_id
  validates_length_of :description, :maximum => 255

  def before_save
    self.permalink = self.name.to_permalink
    self.uuid = get_unique_uuid
  end

  def after_create
    Participation.create!(:user_id => self.admin.id, :contest_instance_id => self.id, :active => true)
  end

  def self.default_name(contest, admin_user)
    "My " + contest.name + " Prediction Contest"
  end

  def self.default_invitation_message(contest, admin_user)
    admin_user.name + " invites you to participate in a contest for predicting the FIFA 2010 World Cup Championship."
  end

  def eql?(other)
    (self.uuid.eql?(other.uuid)) and (self.permalink.eql?(other.permalink))
  end

  def role_for(user)
    return "admin" if user and user.id and user.id.eql?(admin.id)
    "member"
  end

  # ["Active participants: 1. Pending invitations:  0.", "Created at: " + instance.created_at.to_s(:short)]
  def summary_for(user)
    summaries = []
    active_participants_count = Participation.get_stat(:participants_count, :active => 't', :contest_instance_id => self.id)
    participants_summary = "Active participants: " + active_participants_count.to_s + ". "

    if user.is_admin_of?(self)

      if Time.now < self.contest.participation_ends_at
        new_invitations_count = Invitation.get_stat(:contest_invitations_count,  :state => 'n', :contest_instance_id => self.id)
        sent_invitations_count = Invitation.get_stat(:contest_invitations_count,  :state => 's', :contest_instance_id => self.id)
        participants_summary += "New invitations: "  + (new_invitations_count + sent_invitations_count).to_s
      else
        deactivated_participants_count = Participation.get_stat(:participants_count, :active => 'f', :contest_instance_id => self.id)
        participants_summary += "Deactivated participants: " + deactivated_participants_count.to_s
      end
      summaries << participants_summary
      summaries << "Created on: " + self.created_at.to_s(:short)
    else
      summaries << "Admin: " + self.admin.name + ". " + participants_summary
      participation = user.participations.of(self)
      summaries << "Invitation accepted on: " + participation.created_at.to_s(:short)
    end
    summaries
  end

#  def to_param
#    permalink
##    uuid
##    permalink
##    "#{permalink}-#{uuid}"
#  end

private

  def get_unique_uuid(timestamp = Time.now.to_f)
#    timestamp = Time.now.to_f
    seed = self.admin.email + self.name + timestamp.to_s
    uuid = UUIDTools::UUID.md5_create(UUIDTools::UUID_DNS_NAMESPACE, seed).to_s
    ContestInstance.exists?(:uuid => uuid) ? get_unique_uuid(timestamp + 1) : uuid
  end
end
