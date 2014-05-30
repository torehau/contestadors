class PredictionsController < ApplicationController
  before_filter :redirect_if_under_maintenance
  before_filter :set_context_from_request_params
  before_filter :require_contest
  before_filter :before_contest_participation_ends, :only => [:new, :create, :rearrange]
  before_filter :after_contest_participation_ends, :only => :show
  before_filter :require_user, :unless => :preview_available
  before_filter :prediction_state_available, :if => :current_user

  def index
    if @before_contest_participation_ends
      redirect_to :action => "new"
    end
  end

  def new
    @result = @repository.get(@aggregate_root_id)
    @aggregate = @result.current
    set_wizard_and_progress_for_current_user
  end

  def create
    @result = @repository.save(@aggregate_root_id, params[@aggregate_root_type.to_sym][:new_predictions])
    @aggregate = @result.current
    set_wizard_and_progress_for_current_user
    redirect = @aggregate.redirect_on_save?
    set_flash_message(!redirect)
    self.send((redirect ? :redirect_to : :render), :action => :new, :contest => @contest.permalink, :aggregate_root_type => @aggregate_root_type, :aggregate_root_id  => get_aggregate_root_id)
  end

  def rearrange
    @result = @repository.update(@aggregate_root_id, params)
    @aggregate = @result.current
    set_wizard_and_progress_for_current_user
    #redirect_to :path => new_prediction_path(@contest.permalink, @aggregate_root_type, @aggregate_root_id)
    #redirect_to :action => :new, :contest => @contest.permalink, :aggregate_root_id => @aggregate_root_id, :aggregate_root_type => @aggregate_root_type
    render :action => :new
  end

  def show
    @result = params[:command] ? @repository.update(@aggregate_root_id, params) : @repository.get(@aggregate_root_id)
    @aggregate = @result.current
    set_wizard_and_progress_for_current_user
  end

protected

  def set_context_from_request_params
    @contest = selected_tournament#Configuration::Contest.from_permalink_or_first_available(params[:contest])
    @aggregate_root_type = params[:aggregate_root_type]
    @aggregate_root_id = params[:aggregate_root_id]
    @before_contest_participation_ends = before_contest_participation_ends
    @requested_prediction_state = @contest.prediction_state_by_aggregate_root(@aggregate_root_type, @aggregate_root_id)
    @repository = @contest.repository(@aggregate_root_type, current_user)
    @predictions_view_path = "predictable/#{@contest.permalink}/predictions/"
  end

  def set_wizard_and_progress_for_current_user
    if current_user
      @wizard = current_user.summary_of(@contest)
      @wizard.setup_wizard(@aggregate_root_type, @aggregate_root_id)
      @progress = @wizard.prediction_progress

      if @before_contest_participation_ends
        flash.now[:notice] = @wizard.start_hint if @progress == 0
      end
    end
  end

  def set_flash_message(flash_now=false)
    message_type = @aggregate.has_validation_errors? ? :alert : :notice
    message = message_type.eql?(:alert) ? @aggregate.error_msg : render_to_string(:partial => 'successful_predictions_message')

    if flash_now
      flash.now[message_type] = message
    else
      flash[message_type] = message
    end
  end

  def get_aggregate_root_id
    return 'completed' if @wizard and @wizard.is_completed? and not @aggregate.has_validation_errors?
    @aggregate.root_id
  end

  def preview_available
    return false unless @requested_prediction_state
    @requested_prediction_state.preview_available?
  end
  
  def prediction_state_available
    next_available_prediction_state = current_user.next_available_prediction_state(@contest)
    
    if next_available_prediction_state.is_before?(@requested_prediction_state)
      redirect_to new_prediction_path(next_available_prediction_state.request_params)
      return false
    end
  end
end
