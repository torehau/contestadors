class ParticipationObserver < ActiveRecord::Observer

  def after_create(participation)
    contest = participation.contest_instance.contest
    user = participation.user
    summary = user.summary_of(contest)
    unless summary
      summary = user.add_summary(contest)
    end
    score_table_position = participation.contest_instance.score_table_positions.count  + 1 # TODO hack when used after tournament starts, should otherwise be 1
    ScoreTablePosition.create!(:participation_id => participation.id,
                               :contest_instance_id => participation.contest_instance.id,
                               :prediction_summary_id => summary.id,
                               :user_id => user.id,
                               :position => score_table_position)
  end
end
