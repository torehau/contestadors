module PredictionsHelper
  def prediction_template(contest, type)
    "predictable/#{contest}/predictions/#{type}"
  end
  
  def partial_name_prefixed_with_prediction_view_path(partial_name)
    @predictions_view_path + partial_name
  end

  alias_method :p_pref, :partial_name_prefixed_with_prediction_view_path
end
