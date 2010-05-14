class InvitationsController < ApplicationController  
  strip_tags_from_params :only =>  [:create, :update]
  before_filter :require_user
  before_filter :set_context_from_request_params
  before_filter :require_admin, :only => [:new, :create]  

  def new
    if @contest_instance
      session[:selected_contest_id] = @contest_instance.id.to_s
      @invitations = []
      @invitations << Invitation.new(:name => "New Participant Name", :email => "participant@email.com")
    end
  end

  def create
    @invitations = []
    params[:invitations].each {|invite| @invitations << Invitation.new(:contest_instance_id => @contest_instance.id, :name => invite[:name], :email => invite[:email], :sender_id => current_user.id) }
    errors = 0
    @invitations.each {|invitation| errors += 1 if invitation.invalid?}

    if errors > 0
      flash.now[:alert] = "Invalid invitation data given. No invitations sent."
      render :action => :new
    else
      @invitations.each {|invitation| @contest_instance.invitations << invitation}
      @contest_instance.save!
      flash[:notice] = "Valid invitation data given. Invitations will be sent shortly."
      redirect_to contest_invitations_path(:contest => @contest.permalink, :role => "admin", :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid)
    end    
  end

  def index
    @contest_invitations_grid = initialize_grid(Invitation,
      :include => [:existing_user, :participation],
      :conditions => {:contest_instance_id => @contest_instance.id},
      :order => 'invitations.created_at',
      :order_direction => 'desc',
      :per_page => 10
    )
  end

  def pending
    @contest_invitations_grid = initialize_grid(Invitation,
      :include => [:contest_instance, :sender],
      :conditions => {:existing_user_id => current_user.id, :state => Invitation.not_accepted_states},
      :order => 'invitations.created_at',
      :order_direction => 'desc',
      :per_page => 10
    )
  end

  def update
    invitation = Invitation.find(params[:id])
    @contest_instance = invitation.contest_instance
    participation = Participation.new(:user_id => current_user.id,
                         :contest_instance_id => @contest_instance.id,
                         :invitation_id => invitation.id)
                       
    if participation.save
      flash[:notice] = render_to_string(:partial => 'successful_invitation_acceptance_message')
    else
      flash[:alert] = "Something went wrong."
    end
    redirect_to :action => 'pending'
  end

  def accepted
    @contest_invitations_grid = initialize_grid(Invitation,
      :include => [:contest_instance, :sender, :participation],
      :conditions => {:existing_user_id => current_user.id, :state => Invitation.accepted_state},
      :order => 'participations.created_at',
      :order_direction => 'desc',
      :per_page => 10
    )
  end

protected

  def set_context_from_request_params
    @contest = Configuration::Contest.find_by_permalink(params[:contest])
    @role = params[:role]
    @contest_instance = ContestInstance.find_by_permalink_and_uuid(params[:contest_id], params[:uuid])
  end

  def require_admin
    current_user.is_admin_of?(@contest_instance)
  end
end
