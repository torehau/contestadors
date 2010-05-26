class ScoreTablePosition < ActiveRecord::Base
  belongs_to :participation
  belongs_to :prediction_summary
  belongs_to :contest_instance
  belongs_to :user
end
