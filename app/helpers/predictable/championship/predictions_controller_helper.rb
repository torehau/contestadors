module Predictable::Championship::PredictionsControllerHelper
  def prediction_template(type)
    "predictable/championship/predictions/#{type}"
  end

  def successful_prediction_message(aggr_type, aggr_id, new_predictions, wizard)#prediction_state)
    message = ""
    
    unless wizard
      message = successful_prediction_message_for_guest_user
    else
      message = "Predictions succesfully saved for "
      message += send("successful_#{aggr_type.to_s}_prediction_message".to_sym, aggr_id, new_predictions, wizard)
    end
    message
  end

  def is_stage_selected?(stage, aggregate, wizard)
    return false unless (aggregate.root.description.eql?(stage.description))
    if wizard.is_completed?
      return false unless aggregate.is_editing_existing_predictions?
    end
    true
  end

  def predicted_stage_team_div_class(invalidated, selected, is_match_winner)
    div_class_prefix = ""

    if invalidated == true
      div_class_prefix += "invalidated_"
    elsif selected == false and not is_match_winner
      div_class_prefix += "losing_"
    end
    div_class_prefix + "knockout_stage_team"
  end

  private

  def successful_prediction_message_for_guest_user
    "The provided predictions for Group A were valid, and gives the resulting group table seen below."
  end

  def successful_group_prediction_message(aggr_id, new_predictions, wizard)
    message = "Group #{aggr_id}. "

    if new_predictions == true
      message += "You can edit these prediction, or continue to predict "
      message += link_to_next_wizard_step(wizard)
    end
    message
  end

  def link_to_next_wizard_step(wizard)
    message = ""

    if ('a'...'h') === wizard.current_step
      next_group = wizard.next_step.upcase
      message += "#{link_to('Group ' + next_group, new_prediction_path('championship','group', next_group))}."
    elsif 'h'.eql?(wizard.current_step)
      message += "the #{link_to('Knockout Stages', new_prediction_path('championship', 'stage', 'round-of-16'))}."
    end
    message
  end

  def successful_stage_prediction_message(aggr_id, new_predictions, wizard)
    return "the Final and the Third Place Play-off match. Your championship predictions are now completed, but can be edited." if wizard.is_completed?
    "the #{wizard.current_step.gsub('-',' ').capitalize}. "
  end
end
