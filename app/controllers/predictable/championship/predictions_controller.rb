class Predictable::Championship::PredictionsController < ApplicationController
  before_filter :set_contest
  before_filter :init_aggregate
  before_filter :set_repository
  
  def new
    @aggregate = @repository.get
    set_wizard_and_progress_for_current_user
  end

  def create
    @aggregate = @repository.save    
    set_wizard_and_progress_for_current_user
    set_flash_message
    render :action => :new, :aggregate_root_type => @aggregate.type, :aggregate_root_id  => @aggregate.id
  end

  def update
    @repository.update
    redirect_to :action => :new
  end

  protected

  def set_contest
    @contest = Configuration::Contest.find_by_permalink(params[:contest])
  end

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
      @wizard = current_user.summary_of(@contest)
      @progress = @wizard.percentage_completed
    end
  end

  def set_flash_message    
    if not @aggregate.has_validation_errors?
      flash.now[:notice] = render_to_string(:partial => 'successful_predictions_message')
    else
      flash.now[:alert] = "Invalid match results given."
    end
  end
end
