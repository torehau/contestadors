module Predictable::Championship::PredictionsHelper

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
    (stage and @aggregate_root_id.eql?(stage.permalink)) == true
  end

  def knockout_stage_label_div_class(selected, predicted, saveable=true)
    if @before_contest_participation_ends
      if selected == true and predicted == true
        saveable ? "selected_knockout_stage_label" : "unsaveable_selected_knockout_stage_label"
      elsif predicted == true
        saveable ? "knockout_stage_label" : "uneditable_knockout_stage_label"
      else
        saveable ? "undeceided_knockout_stage_label" : "uneditable_knockout_stage_label"
      end
    else
      if predicted == true
        "knockout_stage_label"
      else
        "undeceided_knockout_stage_label"
      end
    end
  end

  def predicted_stage_team_div_class(invalidated, selected, is_match_winner)
    div_class_prefix = ""

    if @before_contest_participation_ends
      if invalidated == true
        div_class_prefix += "invalidated_"
      elsif selected == false
        if is_match_winner == true
          div_class_prefix += "winning_"
        else
          div_class_prefix += "losing_"
        end
      end
    else
      if is_match_winner == true
        div_class_prefix += "winning_"
      else
        div_class_prefix += "losing_"
      end
    end
    div_class_prefix + "knockout_stage_team"
  end

  def group_match_div_class(match)
    @aggregate.has_validation_error_for?(match.id) ? "match_validation_error" : "match"
  end

  private

  def successful_prediction_message_for_guest_user
    "The provided predictions for Group A were valid, and gives the resulting group table seen below."
  end

  def successful_group_prediction_message(aggr_id, new_predictions, wizard)
    message = "Group #{aggr_id}. "

    if new_predictions == true
      message += "You can edit these predictions, or continue to predict "
      message += link_to_next_wizard_step(wizard)
    end
    message
  end

  def link_to_next_wizard_step(wizard)
    message = ""

    if ('A'...'H') === wizard.current_step
      next_group = wizard.next_step.upcase
      message += "#{link_to('Group ' + next_group, new_prediction_path('championship','group', next_group))}."
    elsif 'H'.eql?(wizard.current_step)
      message += "the #{link_to('Knockout Stages', new_prediction_path('championship', 'stage', 'round-of-16'))}."
    end
    message
  end

  def successful_stage_prediction_message(aggr_id, new_predictions, wizard)
    return "the Final and Third Place matches. Your predictions are now completed, but can be edited." if wizard.is_completed?
    "the #{wizard.current_step.gsub('-',' ').capitalize}. "
  end
end
