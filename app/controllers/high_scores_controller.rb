class HighScoresController < ApplicationController
  before_filter :require_user
  before_filter :set_context_from_request_params
  before_filter :require_contest
  
  def show
    @high_score_positions_grid = initialize_grid(HighScoreListPosition,
      :include => [:user, :prediction_summary],
      :conditions => {:configuration_contest_id => @contest.id, :has_predictions => true},
      :order => 'position',
      :order_direction => 'asc',
      :per_page => 30
    )

    if before_contest_participation_ends
      flash.now[:notice] = "The High Score List will be updated during the #{@contest.name}, ranking all Contestadors users based on how well their predictions meet the actual results."
    end  
  end
  
protected  
  
  def set_context_from_request_params
    @contest = selected_tournament
    @before_contest_participation_ends = before_contest_participation_ends
  end
end
