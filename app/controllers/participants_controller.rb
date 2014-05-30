class ParticipantsController < ApplicationController
  include ContestContext, ContestAccessChecker
  before_filter :redirect_if_under_maintenance
  before_filter :require_user
  before_filter :set_context_from_request_params
  before_filter :require_contest
  before_filter :after_contest_participation_ends, :only => :update
  before_filter :require_participation, :only => :index
  before_filter :require_admin, :only => :update

  def index
    save_to_session(@contest_instance)
    array = Configuration::PredictionState.where(:configuration_contest_id => @contest.id).collect {|ps| [ps.state_name, ps]}
    @prediction_states_by_name = Hash[array]
    
    @participants_grid = initialize_grid(Participation,
      :include => [:user],
      :conditions => {:contest_instance_id => @contest_instance.id},
      :order => 'participations.created_at',
      :order_direction => 'desc',
      :per_page => 10
    )
  end

  # upon accepting an invitation sent on mail
  def create
    @invitation = Invitation.find_by_token(params[:invite_code])
    
    if @invitation
      @contest_instance = @invitation.contest_instance

      if @invitation.is_accepted?
        flash[:notice] = "You have already accepted the invitation for the '#{@contest_instance.name}' contest."
        redirect_to contest_participants_path(:contest => @contest_instance.contest.permalink,
                                              :role => @contest_instance.role_for(current_user),
                                              :contest_id => @contest_instance.permalink,
                                              :uuid => @contest_instance.uuid)
        return
      end
      participation = Participation.new(:user_id => current_user.id,
                           :contest_instance_id => @contest_instance.id,
                           :invitation_id => @invitation.id,
                           :active => true)

      if participation.save
        flash[:notice] = "You have now successfully accepted the invitation and joined the '#{@contest_instance.name}' contest."
        redirect_to contest_participants_path(:contest => @contest_instance.contest.permalink,
                                              :role => @contest_instance.role_for(current_user),
                                              :contest_id => @contest_instance.permalink,
                                              :uuid => @contest_instance.uuid)
      else
        raise "Failed to accept invitation with invite code: " + params[:invite_code]
        redirect_to pending_invitations_path("championship")
      end
    else
      raise "Failed to find invitation with invite code: " + (params[:invite_code] ? params[:invite_code] : "nil")
      redirect_to pending_invitations_path("championship")
    end
  end

  # For activation and deactivation - allowed for contest instance admin users only
  def update
    @participation = Participation.find(params[:id])

    respond_to do |format|
      if @participation.update_attributes(params[:participation])
        format.html {redirect_to contest_participants_path(:contest => @contest.permalink, :role => "admin", :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid)}
        format.js { head :ok}
      else
        format.html {redirect_to contest_participants_path(:contest => @contest.permalink, :role => "admin", :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid)}
        format.js { head :unprocessable_entity}
      end
    end
  end

  def show
    @participant = params[:pid] ? Invitation.user_by_token(params[:pid]) : @contest_instance.admin

    if @participant
      @repository = @contest.repository(nil, @participant)
      @predictions = @repository.get_all
    else
      flash[:alert] = "Not possible to identify participant."
      redirect_to contest_score_table_path(:contest => @contest.permalink, :role => @role, :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid)
    end
  end

protected

  def set_context_from_request_params
    set_contest_context(params[:contest], params[:role], params[:contest_id], params[:uuid])
  end
end
