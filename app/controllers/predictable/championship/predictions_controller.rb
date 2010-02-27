class Predictable::Championship::PredictionsController < ApplicationController
  before_filter :init_aggregate, :set_repository
  
  def new
    @aggregate = @repository.get
    set_wizard_and_progress_for_current_user
  end

  def create
    @aggregate = @repository.save    
    set_wizard_and_progress_for_current_user
    set_flash_message
    render :action => :new
  end

  def update
    @repository.update
    redirect_to :action => :new
  end

  protected

  def init_aggregate
    @aggregate = Predictable::Championship::Aggregate.new(current_user, params)
  end

  def set_repository    
    if @aggregate.type.eql?(:group)
      @repository = Predictable::Championship::GroupRepository.new(@aggregate)
    elsif @aggregate.type.eql?(:stage)
      @repository = Predictable::Championship::StageRepository.new(@aggregate)
    end
  end

  def set_wizard_and_progress_for_current_user
    if current_user
      @wizard = current_user.prediction_summary
      @progress = @wizard.percentage_completed
    end
  end

  def set_flash_message
    
    if not @aggregate.has_validation_errors?

      # TODO refactor - send in current_user as local variable to template, giving message also for guest users (not logged in)
      if current_user
        flash.now[:notice] = render_to_string(:partial => 'successful_predictions_message',
                                              :locals => {:state => current_user.prediction_summary.state})
      end
    else
      flash.now[:alert] = "Invalid match results given."
    end
  end
end
