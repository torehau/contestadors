class HighScoresController < ApplicationController
  before_filter :require_user
  before_filter :set_context_from_request_params
  before_filter :require_contest
  
  def show

    if before_contest_participation_ends
      @high_score_list_not_available_message = "High Score List not available yet"
      flash.now[:notice] = "The High Score List will be updated during the #{@contest.name}, ranking all users based on how well their predictions meet the actual results."
    else
      @high_score_positions_grid = initialize_grid(HighScoreListPosition,
        :include => [:user, :prediction_summary],
        :conditions => {:configuration_contest_id => @contest.id, :has_predictions => true},
        :order => 'position',
        :order_direction => 'asc',
        :per_page => 30
      )      
      
      if not current_user.allow_name_in_high_score_lists
        flash.now[:notice] = render_to_string(:partial => 'anonymous_user_message')
      elsif not is_current_tournament_selected
        flash.now[:notice] = "This is the final High Score List of the '#{@contest.name}' tournament."
      end
    end  
  end
  
protected  
  
  def set_context_from_request_params
    @contest = selected_tournament
    @before_contest_participation_ends = before_contest_participation_ends
  end
end
