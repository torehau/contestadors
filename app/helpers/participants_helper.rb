module ParticipantsHelper
  def objectives_meet_div_class_for(objectives_meet)
    div_class = "objectives_meet"

    if objectives_meet
      div_class += "_" + objectives_meet.to_s
    end
    div_class
  end
end
