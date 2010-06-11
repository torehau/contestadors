class ScoreTablePosition < ActiveRecord::Base
  include Comparable
  belongs_to :participation
  belongs_to :prediction_summary
  belongs_to :contest_instance
  belongs_to :user

  def <=> (other)
    score_compare = other.prediction_summary.total_score <=> self.prediction_summary.total_score
    return score_compare unless score_compare == 0
    other.prediction_summary.map <=> self.prediction_summary.map
  end
end
