class Predictable::Championship::PredictionsController < ApplicationController
  before_filter :extract_aggregate_info
  
  def new
    @group, @predictions_exists = @repository.get
  end

  def create
    @group, saved_ok = @repository.save(params[@aggregate_root_type])
    
    if saved_ok
      flash.now[:notice] = "Predictions succesfully saved."
    else
      flash.now[:alert] = "An error occured when saving the predictions."
    end
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
end
