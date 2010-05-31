class ParticipantsController < ApplicationController
  include ContestContext, ContestAccessChecker
  before_filter :require_user
  before_filter :set_context_from_request_params
  before_filter :after_contest_participation_ends, :only => :update
  before_filter :require_participation, :only => :index
  before_filter :require_admin, :only => :update

  def index
    session[:selected_contest_id] = @contest_instance.id.to_s if @contest_instance
    
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

protected

  def set_context_from_request_params
    set_contest_context(params[:contest], params[:role], params[:contest_id], params[:uuid])
  end
end
