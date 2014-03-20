class ScoreTablesController < ApplicationController
  include ContestContext, ContestAccessChecker
  before_filter :require_user
  before_filter :set_context_from_request_params
  before_filter :require_contest
  before_filter :require_participation


  def show
    save_to_session(@contest_instance)
    @positions_grid = initialize_grid(ScoreTablePosition,
      :include => [:user, :prediction_summary, :participation],
      :conditions => {:contest_instance_id => @contest_instance.id, :participations => {:active => true}},
      :order => (before_contest_participation_ends ? 'prediction_summaries.map' : 'position'),
      :order_direction => (before_contest_participation_ends ? 'desc' : 'asc'),
      :per_page => 30
    )

    if before_contest_participation_ends
      flash.now[:notice] = "The Score Table will be updated during the #{@contest.name}, ranking the participants based on how well their predictions meet the actual results."
    end
  end

protected

  def set_context_from_request_params
    set_contest_context(params[:contest], params[:role], params[:contest_id], params[:uuid])
  end
end
