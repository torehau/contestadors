class Predictable::Championship::PredictionsController < ApplicationController
  before_filter :extract_aggregate_info
  
  def new
    @aggregate_root, @predictions_exists = @repository.get
    set_view_variables
  end

  def create
    @aggregate_root, @validation_errors, @new_predictions = @repository.save(params[@aggregate_root_type])
    set_view_variables
    set_flash_message
    render :action => :new
  end

  def update

    if @aggregate_root_type.eql?(:group)
      @move_operation = params[:move].to_sym
      @position_id = params[:id].to_i
      @repository.update(@position_id, @move_operation)
    end
    redirect_to :action => :new
  end

  protected

  def extract_aggregate_info
    @aggregate_root_type = params[:aggregate_root_type].to_sym
    @aggregate_root_id = params[:aggregate_root_id]
    
    if @aggregate_root_type.eql?(:group)
      @repository = Predictable::Championship::GroupRepository.new(current_user, @aggregate_root_id)
    elsif @aggregate_root_type.eql?(:stage)
      @repository = Predictable::Championship::StageRepository.new(current_user, @aggregate_root_id)
    end
  end

  def set_view_variables
    @wizard = current_user.prediction_summary
    @progress = current_user.prediction_summary.percentage_completed
    
    if @aggregate_root_type.eql?(:group)
      @group_table_rearrangable = (current_user and @aggregate_root.is_rearrangable?)
    elsif @aggregate_root_type.eql?(:stage)
#      @aggregate_root_id = @aggregate_root.permalink
      @stages = Predictable::Championship::Stage.knockout_stages       
      @predicted_stages = @aggregate_root[1]
      @aggregate_root = @aggregate_root[0]
      @third_place = Predictable::Championship::Match.find_by_description("Third Place")
    end
  end

  def set_flash_message
    
    if @validation_errors.empty?

      if current_user
        flash.now[:notice] = render_to_string(:partial => 'successful_predictions_message',
                                              :locals => {:state => current_user.prediction_summary.state})
      end
    else
      flash.now[:alert] = "Invalid match results given."
    end
  end
end
