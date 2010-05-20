class Participation < ActiveRecord::Base
  belongs_to :user
  belongs_to :contest_instance
  belongs_to :invitation
  validates_presence_of :user_id, :contest_instance_id
  validates_uniqueness_of :user_id, :scope => :contest_instance_id
  define_statistic :participants_count, :count => :all, :filter_on => {:active => 'active = ?', :contest_instance_id => 'contest_instance_id = ?'}

  def after_create
    if self.invitation
      self.invitation.accept!
    end
  end  
end
