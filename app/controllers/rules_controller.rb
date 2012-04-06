class RulesController < ApplicationController
  before_filter :require_user
  before_filter :set_context_from_request_params

  def predictions
  end

  def prediction_contests
  end

  def score_calculations
  end

  private

  def set_context_from_request_params
    @tournament_permalink = params[:contest]
  end
end
