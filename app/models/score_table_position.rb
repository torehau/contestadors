class ScoreTablePosition < ActiveRecord::Base
  include Comparable
  belongs_to :participation
  belongs_to :prediction_summary
  belongs_to :contest_instance
  belongs_to :user

  def <=> (other)
    active_compare = compare_active_participation(other)
    return active_compare unless active_compare == 0
    score_compare = other.prediction_summary.total_score <=> self.prediction_summary.total_score
    return score_compare unless score_compare == 0
    other.prediction_summary.map <=> self.prediction_summary.map
  end

  private

  def compare_active_participation(other)
    return 0 if self.participation.active.eql?(other.participation.active)
    if self.participation.active == true
      -1
    else
      1
    end
  end
end
