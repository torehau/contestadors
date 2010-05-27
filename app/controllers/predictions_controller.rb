class PredictionsController < ApplicationController
  before_filter :set_context_from_request_params
  before_filter :before_contest_participation_ends, :only => [:new, :create, :update]

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
    self.send((redirect ? :redirect_to : :render), :action => :new, :aggregate_root_type => @aggregate_root_type, :aggregate_root_id  => get_aggregate_root_id)
  end

  def update
    @result = @repository.update(@aggregate_root_id, params)
    @aggregate = @result.current
    set_wizard_and_progress_for_current_user
    render :action => :new
  end

protected

  def set_context_from_request_params
    @contest = Configuration::Contest.find_by_permalink(params[:contest])
    @predictions_view_path = "predictable/#{@contest.permalink}/predictions/"
    @aggregate_root_type = params[:aggregate_root_type]
    @aggregate_root_id = params[:aggregate_root_id]
    @repository = @contest.repository(@aggregate_root_type, current_user)
  end

  def set_wizard_and_progress_for_current_user
    if current_user
      @wizard = current_user.summary_of(@contest)
      @wizard.setup_wizard
      @progress = @wizard.prediction_progress
      flash.now[:notice] = @wizard.start_hint if @progress == 0
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
end