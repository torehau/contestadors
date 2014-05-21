class ContestsController < ApplicationController
  include ContestContext, ContestAccessChecker
  strip_tags_from_params :only =>  [:create, :update]
  before_filter :add_request_uri_to_cookie, :only => :join
  before_filter :require_user
  before_filter :set_context_from_request_params
  before_filter :require_participation, :only => :show
  before_filter :require_admin, :only => [:edit, :update]
  helper LaterDude::CalendarHelper

  def index
    @contest_instances = current_user.instances_of(@contest, @role.to_sym)
    @contest_instance = get_contest_instance_from_session
    set_no_contests_message
      @contests_grid = initialize_grid(ContestInstance,
        :include => [:admin, :participations],
        :conditions => {:id => @contest_instances},
        :order => 'name',
        :order_direction => 'asc',
        :per_page => 10
      )
  end

  def show
    save_to_session(@contest_instance)
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
    flash.now[:notice] = "Create a new contest for others to join. The name and message you provide below will be included in the email to people you invite."
  end

  def create
    @contest_instance = ContestInstance.new(params[:contest_instance])
    
    if verify_recaptcha
      @contest_instance.admin_user_id = current_user.id
      @contest_instance.configuration_contest_id = @contest.id

      if @contest_instance.save
        flash[:notice] = "New contest '" +  @contest_instance.name + "' successfully created! You may now invite people to join it."
        redirect_to new_contest_invitation_path(:contest => @contest.permalink, :role => "admin", :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid)
        flash.delete(:recaptcha_error)
        return
      else
        set_error_details
      end
    else
      @focused_field_id = "recaptcha_response_field"
      flash.now[:alert] = "Word verification response is incorrect, please try again."
    end
    flash.delete(:recaptcha_error)
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

  def upcoming_events
    if @contest_instance
      @participants = @contest_instance.active_participants
      @repository = @contest.repository(nil, nil)
      @predictions_by_predictable = @repository.get_all_upcoming(@participants)
    end
  end

  def latest_results
    if @contest_instance
      @participants = @contest_instance.active_participants
      @repository = @contest.repository(nil, nil)
      @predictions_by_predictable = @repository.get_all_latest(@participants)
    end
  end

  def join
    if @contest_instance and not @contest_instance.allow_join_by_url
      #flash[:alert] = "You must have an email invitation to join this contest"
      redirect_to new_contest_path(@contest.permalink, "admin")
      return
    end

    save_to_session(@contest_instance)

    if current_user.is_participant_of?(@contest_instance)
      flash[:alert] = "You are already a member of this contest"
      redirect_to contest_participants_path(:contest => @contest.permalink, :role => @role, :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid)
      return
    end
  end

  def join_confirm
    participation = Participation.new(:user_id => current_user.id,
                                      :contest_instance_id => @contest_instance.id,
                                      :active => true)

    if participation.save
      flash[:notice] = "You have now successfully joined the '#{@contest_instance.name}' contest."
      redirect_to contest_participants_path(:contest => @contest_instance.contest.permalink,
                                            :role => @contest_instance.role_for(current_user),
                                            :contest_id => @contest_instance.permalink,
                                            :uuid => @contest_instance.uuid)
    else
      raise "Failed to join contest: " + @contest_instance.name
      render :action => :join
    end
  end

protected

  def set_context_from_request_params
    set_contest_context(params[:contest], params[:role], params[:id], params[:uuid])
  end

  def set_no_contests_message
    if @contest_instances.empty?
      @no_contests_message = case @role.to_sym
        when :admin then "You have not created any contests for the '#{@contest.name}' tournament yet"
        when :member then "You have not accepted or received any '#{@contest.name}' contest invitations yet"
        else "You do not participate in any contests for the '#{@contest.name}' tournament yet"
      end
    end
  end

  def set_error_details
    if @contest_instance.errors.on(:name)
      flash.now[:alert] = "The name was not valid."
    else
      flash.now[:alert] = "Maximum 1000 characters allowed for the invitation message."
      @focused_field_id = "contest_instance_description"
    end
  end
  
  def add_request_uri_to_cookie
    cookies[:return_to] = request.request_uri
  end
end
