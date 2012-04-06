class Participation < ActiveRecord::Base
  after_create :accept_invitation, :init_score_table_position
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

  def init_score_table_position
    ScoreTablePosition.create!(:participation_id => self.id,
                               :contest_instance_id => self.contest_instance.id,
                               :prediction_summary_id => self.user.summary_of(self.contest_instance.contest).id,
                               :user_id => self.user.id,
                               :position => 1)
  end
end
