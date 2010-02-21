module Predictable::Championship::PredictionsControllerHelper
  def prediction_template(type)
    "predictable/championship/predictions/#{type}"
  end

  def successful_prediction_message(aggr_type, aggr_id, new_predictions, prediction_state)
    message = "Predictions succesfully saved for "
    
    if aggr_type.eql?(:group)
      message += "Group #{aggr_id}. "

      if new_predictions == true

        message += "You can edit these prediction, or continue to predict "

        if ('a'...'h') === prediction_state
          next_group = aggr_id.succ
          message += "#{link_to('Group ' + next_group, new_prediction_path('group', next_group))}."
        elsif 'h'.eql?(prediction_state)
          message += "#{link_to('Round of 16', new_prediction_path('stage', 'round-of-16'))}."
        end
      end
    elsif aggr_type.eql?(:stage)
      message += "Stage #{aggr_id.gsub('-',' ').capitalize}. "
    end
    message
  end
end
