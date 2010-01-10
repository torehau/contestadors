class Predictable::Championship::PredictionsController < ApplicationController
  before_filter :extract_aggregate_info
  
  def new
    @group, @predictions_exists = @repository.get
    @group_table = @group.table_positions.sort{|a,b| a.pos <=> b.pos}
  end

  def create
    result = @repository.save params[@aggregate_root_type]
    @group, saved_ok = result[0], result[1]
    
    if saved_ok
      flash.now[:notice] = "Predictions succesfully saved."
    else
      flash.now[:alert] = "An error occured when saving the predictions."
    end
    @group_table = @group.table_positions.sort{|a,b| a.pos <=> b.pos}
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
