class Predictable::Championship::PredictionsController < ApplicationController
  before_filter :extract_aggregate_info
  
  def new
    @group, @predictions_exists = @repository.get
  end

  def create
    @group, @validation_errors = @repository.save(params[@aggregate_root_type])
    set_flash_message
    render :action => :new
  end

  def update

    if current_user and @aggregate_root_type.eql?(:group)
      @move_operation = params[:move].to_sym
      @position_id = params[:id].to_i
      @repository.update(@position_id, @move_operation)
    end
    @group, @predictions_exists = @repository.get
    render :action => :new
  end

  protected

  def extract_aggregate_info
    @aggregate_root_type = params[:aggregate_root_type].to_sym
    @aggregate_root_id = params[:aggregate_root_id]
    
    if @aggregate_root_type.eql?(:group)
      @repository = Predictable::Championship::GroupRepository.new(current_user, @aggregate_root_id)
    end
  end

  def set_flash_message
    
    if @validation_errors.empty?

      if current_user
        flash.now[:notice] = "Predictions succesfully saved."
      end
    else
      flash.now[:alert] = "Invalid match results given."
    end
  end
end
