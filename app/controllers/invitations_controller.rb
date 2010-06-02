class InvitationsController < ApplicationController
  include ContestContext, ContestAccessChecker
  strip_tags_from_params :only => :create
  before_filter :require_user
  before_filter :set_context_from_request_params
  before_filter :before_contest_participation_ends, :except => :index
  before_filter :require_admin, :only => [:new, :create, :index]

  def new
    if @contest_instance
      session[:selected_contest_id] = @contest_instance.id.to_s
      @invitations = []
      @invitations << Invitation.new(:name => "New Participant Name", :email => "participant@email.com")
    end
  end

  def create
    @invitations = []
    params[:invitations].each {|invite| @invitations << Invitation.new(:contest_instance_id => @contest_instance.id, :name => invite[:name], :email => invite[:email].try(:gsub, /\s/, ''), :sender_id => current_user.id) }
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
    set_contest_context(params[:contest], params[:role], params[:contest_id], params[:uuid])
  end
end
