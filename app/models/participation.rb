class Participation < ActiveRecord::Base
  belongs_to :user
  belongs_to :contest_instance
  belongs_to :invitation
  has_one :score_table_position
  validates_presence_of :user_id, :contest_instance_id
  validates_uniqueness_of :user_id, :scope => :contest_instance_id
  define_statistic :participants_count, :count => :all, :filter_on => {:active => 'active = ?', :contest_instance_id => 'contest_instance_id = ?'}

  def after_create
    if self.invitation
      self.invitation.accept!
    end
    ScoreTablePosition.create!(:participation_id => self.id,
                               :contest_instance_id => self.contest_instance.id,
                               :prediction_summary_id => self.user.summary_of(self.contest_instance.contest).id,
                               :user_id => self.user.id,
                               :position => 1)
  end  
end
