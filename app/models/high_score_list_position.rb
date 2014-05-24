class HighScoreListPosition < ActiveRecord::Base
  include Comparable
  belongs_to :user
  belongs_to :contest, :class_name => "Configuration::Contest", :foreign_key => 'configuration_contest_id'
  belongs_to :prediction_summary
  
  def participant_name
    user.allow_name_in_high_score_lists ? user.name : "Anonymous"
  end

  def <=> (other)
    has_predictions_compare = compare_has_predictions(other)
    return has_predictions_compare unless has_predictions_compare == 0
    score_compare = other.prediction_summary.total_score <=> self.prediction_summary.total_score
    return score_compare unless score_compare == 0
    other.prediction_summary.map <=> self.prediction_summary.map
  end    

  private

  def compare_has_predictions(other)
    return 0 if self.has_predictions? == other.has_predictions?
    (self.has_predictions? == true) ? -1 : 1
  end  
end
