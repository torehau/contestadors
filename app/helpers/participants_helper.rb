module ParticipantsHelper
  def objectives_meet_div_class_for(objectives_meet)
    div_class = "objectives_meet"

    if objectives_meet
      div_class += "_" + objectives_meet.to_s
    end
    div_class
  end
  
  def stage_objectives_meet_div_class_for(objectives_meet_by_stage_id, stage)
    objectives_meet = objectives_meet_by_stage_id[stage.id]
    
    if objectives_meet
      return "objectives_meet_" + objectives_meet.to_s
    end
    
    while objectives_meet.nil? and stage.description != "Round of 16" do
      stage = stage.previous
      objectives_meet = objectives_meet_by_stage_id[stage.id]
    end
    (!objectives_meet.nil? and objectives_meet == 0) ? "objectives_meet_0" : "objectives_meet"  
  end
end
