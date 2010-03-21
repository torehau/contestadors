class PredictionsController < ApplicationController
  before_filter :set_contest, :set_repository, :set_predictions_view_path, :except => :edit

  def new
    @aggregate = @repository.get
    set_wizard_and_progress_for_current_user
  end

  def create
    @aggregate = @repository.save
    set_wizard_and_progress_for_current_user

    if @aggregate.type.eql?(:group)
      set_flash_message(true)
      render :action => :new, :aggregate_root_type => @aggregate.type, :aggregate_root_id  => @aggregate.id
    else
      set_flash_message
      aggregate_root_id = @wizard.is_completed? ? 'completed' : @aggregate.id
      redirect_to :action => :new, :aggregate_root_type => @aggregate.type, :aggregate_root_id  => aggregate_root_id
    end
  end

  def edit
    redirect_to :action => :new, :contest => params[:contest], :aggregate_root_type => params[:aggregate_root_type], :aggregate_root_id  => params[:aggregate_root_id], :operation => 'edit'
  end

  def update
    @repository.update
    redirect_to :action => :new
  end

  protected

  def set_contest
    @contest = Configuration::Contest.find_by_permalink(params[:contest])
  end

  def set_repository
    @repository = @contest.repository(current_user, params)
  end

  def set_predictions_view_path
    @predictions_view_path = "predictable/#{@contest.permalink}/predictions/"
  end

  def set_wizard_and_progress_for_current_user
    if current_user
      @wizard = current_user.summary_of(@contest)
      @wizard.setup_wizard
      @progress = @wizard.prediction_progress
    end
  end

  def set_flash_message(flash_now=false)
    message_type = @aggregate.has_validation_errors? ? :alert : :notice
    message = message_type.eql?(:alert) ? "Invalid match results given." : render_to_string(:partial => 'successful_predictions_message')

    if flash_now
      flash.now[message_type] = message
    else
      flash[message_type] = message
    end
  end
end