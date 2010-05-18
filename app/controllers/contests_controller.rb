class ContestsController < ApplicationController
  strip_tags_from_params :only =>  [:create, :update]
  before_filter :require_user
  before_filter :set_context_from_request_params
  before_filter :require_participation, :only => :show
  before_filter :require_admin, :only => [:edit, :update]
  helper LaterDude::CalendarHelper

  def index
    @contest_instances = current_user.instances_of(@contest, @role.to_sym)
    @contest_instance = get_contest_instance_from_session
    set_no_contests_message
  end

  def show
    session[:selected_contest_id] = @contest_instance.id.to_s if @contest_instance
    @date = Time.now
#    @matches = Predictable::Championship::Match.find(:all)
#    @date = @matches.first.play_date
#    @start_date = Date.new(@date.year, @date.month, @date.day)
#    @end_date = @start_date + 7
#    @matches = Predictable::Championship::Match.find(:all, :conditions => ['play_date between ? and ?', @start_date, @start_date + 7])
  end
  
  def new
    @contest_instance = ContestInstance.new(:name => ContestInstance.default_name(@contest, current_user),
                    :description => ContestInstance.default_invitation_message(@contest, current_user))
  end

  def create
    @contest_instance = ContestInstance.new(params[:contest_instance])
    
    if verify_recaptcha
      @contest_instance.admin_user_id = current_user.id
      @contest_instance.configuration_contest_id = @contest.id

      if @contest_instance.save
        flash[:notice] = "New contest '" +  @contest_instance.name + "' successfully created! You may now invite people to join it."
        redirect_to new_contest_invitation_path(:contest => @contest.permalink, :role => "admin", :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid)
        return
      else
        set_error_details
      end
    else
      @focused_field_id = "recaptcha_response_field"
      flash.now[:alert] = "Word verification response is incorrect, please try again."
    end
    render :action => :new
  end

  def edit
  end

  def update   
    @contest_instance.name = params[:contest_instance][:name]
    @contest_instance.description = params[:contest_instance][:description]

    if @contest_instance.save
      flash.now[:notice] = "Contest successfully updated."
    else
      set_error_details
    end
    render :action => :edit
  end

protected

  def set_context_from_request_params
    @contest = Configuration::Contest.find_by_permalink(params[:contest])
    @role = params[:role]
    @contest_instance = ContestInstance.find_by_permalink_and_uuid(params[:id], params[:uuid])
  end

  def require_participation
    current_user.is_participant_of?(@contest_instance)
  end

  def require_admin
    current_user.is_admin_of?(@contest_instance)
  end

  def set_no_contests_message
    if @contest_instances.empty?
      @no_contests_message = case @role.to_sym
        when :admin then "You have not created any contests yet"
        when :member then "You have not accepted or recieved any contest invitations yet"
        else "You do not participate in any contests yet"
      end
    end
  end

  def set_error_details
    if @contest_instance.errors.on(:name)
      flash.now[:alert] = "The name was not valid."
    else
      flash.now[:alert] = "Maximum 255 characters allowed for the invitation message."
      @focused_field_id = "contest_instance_description"
    end
  end
end
