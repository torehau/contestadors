class ParticipationObserver < ActiveRecord::Observer

  def after_create(participation)
    contest = participation.contest_instance.contest
    user = participation.user
    summary = user.summary_of(contest)
    unless summary
      summary = user.add_summary(contest)
    end
    ScoreTablePosition.create!(:participation_id => participation.id,
                               :contest_instance_id => participation.contest_instance.id,
                               :prediction_summary_id => summary.id,
                               :user_id => user.id,
                               :position => 1)
  end
end
