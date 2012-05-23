class InvitationsController < ApplicationController
  include ContestContext, ContestAccessChecker
  strip_tags_from_params :only => :create
  before_filter :require_user
  before_filter :set_context_from_request_params
  before_filter :require_contest
  before_filter :before_contest_participation_ends, :except => :index
  before_filter :require_admin, :only => [:new, :copy, :create, :index]

  def new
    if @contest_instance
      session[:selected_contest_id] = @contest_instance.id.to_s
      @invitations = []
      @invitations << Invitation.new_with_dummy_values
      @previous_contests = current_user.previously_administered_contests(@contest)
    end
  end

  def copy
    if @contest_instance
      session[:selected_contest_id] = @contest_instance.id.to_s

      if params[:previous_contests] and params[:previous_contests].to_i > 0
        @previous_contest = ContestInstance.find(params[:previous_contests])
      end

      if @previous_contest and current_user.is_admin_of?(@previous_contest)
        @invitations = @previous_contest.copy_invitations_for_active_participants(@contest_instance.id)
      else
        @invitations = []
        @invitations << Invitation.new_with_dummy_values
      end
      @previous_contests = current_user.previously_administered_contests(@contest)
    end
    render :new
  end

  def create
    @invitations = []
    params[:invitations].each {|invite| @invitations << Invitation.new(:contest_instance_id => @contest_instance.id, :name => invite[:name], :email => invite[:email].try(:gsub, /\s/, ''), :sender_id => current_user.id) }
    errors = 0
    @invitations.each {|invitation| errors += 1 if invitation.invalid?}

    if errors > 0
      flash.now[:alert] = "Invalid invitation data given. No invitations sent."
      @previous_contests = current_user.previously_administered_contests(@contest)
      render :action => :new
    else
      @invitations.each {|invitation| @contest_instance.invitations << invitation}
      @contest_instance.save!
      flash[:notice] = "Valid invitation data given. Invitations will be sent shortly."
      redirect_to contest_invitations_path(:contest => @contest.permalink, :role => "admin", :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid)
    end    
  end

  def index
    invitations = Invitation.where(:contest_instance_id => @contest_instance.id)

    if invitations.empty?
      @no_invitations_message = "You have not sent any invitations for this contest yet"
    else
      @contest_invitations_grid = initialize_grid(Invitation,
        :include => [:existing_user, :participation],
        :conditions => {:id => invitations},
        :order => 'invitations.created_at',
        :order_direction => 'desc',
        :per_page => 10
      )
    end
  end

  def pending
    invitations = Invitation.where(:existing_user_id => current_user.id, :state => Invitation.not_accepted_states).select{|inv| inv if inv.contest.id == @contest.id}

    if invitations.empty?
      @no_invitations_message = "You have no pending '#{@contest.name}' contest invitations"
    else
      @contest_invitations_grid = initialize_grid(Invitation,
        :include => [:contest_instance, :sender],
        :conditions => {:id => invitations},
        :order => 'invitations.created_at',
        :order_direction => 'desc',
        :per_page => 10
      )
    end
  end

  def accepted
    invitations = Invitation.where(:existing_user_id => current_user.id, :state => Invitation.accepted_state).select{|inv| inv if inv.contest.id == @contest.id}

    if invitations.empty?
      @no_invitations_message = "You have not accepted or received any '#{@contest.name}' contest invitations"
    else
      @contest_invitations_grid = initialize_grid(Invitation,
        :include => [:contest_instance, :sender, :participation],
        :conditions => {:id => invitations},
        :order => 'participations.created_at',
        :order_direction => 'desc',
        :per_page => 10
      )
    end
  end

protected

  def set_context_from_request_params
    set_contest_context(params[:contest], params[:role], params[:contest_id], params[:uuid])
  end
end
