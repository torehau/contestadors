module ParticipantsHelper
  def objectives_meet_div_class_for(predictable)
    div_class = "objectives_meet"

    if predictable.objectives_meet
      div_class += "_" + predictable.objectives_meet.to_s
    end
    div_class
  end
end
