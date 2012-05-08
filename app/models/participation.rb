class Participation < ActiveRecord::Base
  after_create :accept_invitation
  belongs_to :user
  belongs_to :contest_instance
  belongs_to :invitation
  has_one :score_table_position
  validates_presence_of :user_id, :contest_instance_id
  validates_uniqueness_of :user_id, :scope => :contest_instance_id
  define_statistic :participants_count, :count => :all, :filter_on => {:active => 'active = ?', :contest_instance_id => 'contest_instance_id = ?'}


private

  def accept_invitation
    if self.invitation
      self.invitation.accept!
    end
  end
end
