require "mods.rb"

class ContestInstance < ActiveRecord::Base
  before_save :init_identifiers
  after_create :make_admin_first_participant
  belongs_to :contest, :class_name => "Configuration::Contest", :foreign_key => "configuration_contest_id"
  belongs_to :admin, :class_name => "User", :foreign_key => "admin_user_id"
  has_many :invitations, :dependent => :destroy
  has_many :participations, :dependent => :destroy do
    def active
      find(:all, :conditions => {:active => true})
    end
  end
  has_many :score_table_positions, :dependent => :destroy
  validates_presence_of :name, :admin_user_id, :configuration_contest_id
  validates_length_of :description, :maximum => 1000


  def self.default_name(contest, admin_user)
    "My " + contest.name + " Prediction Contest"
  end

  def self.default_invitation_message(contest, admin_user)
    admin_user.name + " invites you to join a prediction contest at Contestadors for the " + contest.name + " Soccer Tournament."
  end

  def eql?(other)
    (self.uuid.eql?(other.uuid)) and (self.permalink.eql?(other.permalink))
  end

  def role_for(user)
    user and user.id and user.id.eql?(admin.id) ? "admin" : "member"
  end

  def full_name
    self.contest.name + ": " + self.name
  end

  # ["Active participants: 1. Pending invitations:  0.", "Created at: " + instance.created_at.to_s(:short)]
  #def summary_for(user)
  #  summaries = []
  #  active_participants_count = Participation.get_stat(:participants_count, :active => 't', :contest_instance_id => self.id)
  #  participants_summary = "Active participants: " + active_participants_count.to_s + ". "
  #
  #  if user.is_admin_of?(self)
  #
  #    if Time.now < self.contest.participation_ends_at
  #      new_invitations_count = Invitation.get_stat(:contest_invitations_count,  :state => 'n', :contest_instance_id => self.id)
  #      sent_invitations_count = Invitation.get_stat(:contest_invitations_count,  :state => 's', :contest_instance_id => self.id)
  #      participants_summary += "New invitations: "  + (new_invitations_count + sent_invitations_count).to_s
  #    else
  #      deactivated_participants_count = Participation.get_stat(:participants_count, :active => 'f', :contest_instance_id => self.id)
  #      participants_summary += "Deactivated participants: " + deactivated_participants_count.to_s
  #    end
  #    summaries << participants_summary
  #    summaries << "Created on: " + self.created_at.to_s(:short)
  #  else
  #    summaries << "Admin: " + self.admin.name + ". " + participants_summary
  #    participation = user.participations.of(self)
  #    summaries << "Invitation accepted on: " + participation.created_at.to_s(:short)
  #  end
  #  summaries
  #end

  def active_participants
    self.participations.active.collect {|participation| participation.user }
  end

  def copy_invitations_for_active_participants(other_contest_instance_id)
    invitations = []
    self.participations.active.each do |participant|
      if participant.invitation
        invitations << Invitation.new(:contest_instance_id => other_contest_instance_id, :name => participant.invitation.name, :email => participant.invitation.email)
      end
    end
    invitations
  end

  def update_score_table_positions
    previous = nil
    position, delta = 1, 1
    self.score_table_positions.sort.each do |current|
      if previous
        
        if (current <=> previous) == 0
          delta += 1
        else
          position += delta
          delta = 1
        end
      end
      current.previous_position = current.position
      current.position = position
      current.save!
      previous = current
    end
  end

  def is_available_for?(user)
    (allow_join_by_url and Time.now < contest.participation_ends_at) or user.is_participant_of?(self)
  end

  def join_link
    plink = new_record? ? name.to_permalink : permalink
    unique_identifier = new_record? ? 'dffb3223-b369-32e4-a3f5-4c4776b7d0c4' : uuid
    "http://www.contestadors.com/championship/member/contests/#{plink}/join?uuid=#{unique_identifier}"
  end

private

  def init_identifiers
    self.permalink = self.name.to_permalink
    self.uuid = get_unique_uuid
  end

  def make_admin_first_participant
    Participation.create!(:user_id => self.admin.id, :contest_instance_id => self.id, :active => true)
  end

  def get_unique_uuid(timestamp = Time.now.to_f)
    uuid = UUIDTools::UUID.md5_create(UUIDTools::UUID_DNS_NAMESPACE, get_seed(timestamp)).to_s
    ContestInstance.exists?(:uuid => uuid) ? get_unique_uuid(timestamp + 1) : uuid
  end

  def get_seed(timestamp)
    seed = ""
    if self.admin and self.admin.name
      seed += self.admin.name
    end

    if self.name
      seed += self.name
    end
    seed += timestamp.to_s
    seed
  end
end
