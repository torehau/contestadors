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
      message += "#{link_to('Round of 16', new_prediction_path('championship', 'stage', 'round-of-16'))}."
    end
    message
  end

  def successful_stage_prediction_message(aggr_id, new_predictions, wizard)
    "Stage #{wizard.current_step.gsub('-',' ').capitalize}. "
  end
end
