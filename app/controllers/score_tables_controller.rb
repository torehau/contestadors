class ScoreTablesController < ApplicationController
  include ContestContext, ContestAccessChecker
  before_filter :require_user
  before_filter :set_context_from_request_params
  before_filter :require_participation

  def show
    @positions_grid = initialize_grid(ScoreTablePosition,
      :include => [:user, :prediction_summary],
      :conditions => {:contest_instance_id => @contest_instance.id},
      :order => 'position',
      :order_direction => 'desc',
      :per_page => 10
    )
  end

protected

  def set_context_from_request_params
    set_contest_context(params[:contest], params[:role], params[:contest_id], params[:uuid])
  end
end
