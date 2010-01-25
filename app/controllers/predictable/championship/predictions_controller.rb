class Predictable::Championship::PredictionsController < ApplicationController
  before_filter :extract_aggregate_info
  
  def new
    @aggregate_root, @predictions_exists = @repository.get
    set_view_conditionals
  end

  def create
    @aggregate_root, @validation_errors = @repository.save(params[@aggregate_root_type])
    set_view_conditionals(true)
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

  def set_view_conditionals(reload=false)
    
    if @aggregate_root_type.eql?(:group)
      @group_table_rearrangable = (current_user and @aggregate_root.is_rearrangable?)

      if (current_user and (session[:all_groups_completed].nil? or (reload==true)))
        category = Configuration::Category.find_by_description("Group Tables")
        session[:all_groups_completed] = current_user.predictions_completed_for?(category)
      end
      @all_groups_completed = session[:all_groups_completed] ? session[:all_groups_completed] : false
    elsif @aggregate_root_type.eql?(:stage)
      session[:all_groups_completed] = true
      @all_groups_completed = session[:all_groups_completed]
      @stages = Predictable::Championship::Stage.find(:all, :conditions => {:description => ["Round of 16", "Quarter-finals", "Semi-finals", "Final"]})
      @third_place = Predictable::Championship::Match.find_by_description("Third Place")
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
