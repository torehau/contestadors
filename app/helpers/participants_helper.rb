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
  
  def match_objectives_meet_div_class_for(winner_team, stage, match)
  
    #if match.settled?    
    return match.winner_team.id == winner_team.id ? "objectives_meet_1" : "objectives_meet_0"
    #end   
    
    if match.is_third_place_play_off?      
      return "objectives_meet_0" if match.stage.previous.teams.where(:id => winner_team.id).count == 1# and winner_team.is_through_to_stage?(stage.previous)
    end
  
    objectives_meet_by_stage_id = winner_team.objectives_meet_for
    objectives_meet = objectives_meet_by_stage_id[stage.id]
    
    #if objectives_meet
     # return "objectives_meet_" + objectives_meet.to_s
    #end
    
    while objectives_meet.nil? and stage.description != "Round of 16" do
      stage = stage.previous
      objectives_meet = objectives_meet_by_stage_id[stage.id]
    end
    (!objectives_meet.nil? and objectives_meet == 0) ? "objectives_meet_0" : "objectives_meet"  
  end  
end
