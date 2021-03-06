class UserSessionsController < ApplicationController
  before_filter :redirect_if_under_maintenance, :only => [:index]
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy

  def index
    #flash[:notice] = (session[:return_to] ? session[:return_to].to_s : " return to not set ") + (before_contest_participation_ends ? " is before contest participation ends" : " is after contest participation ends")
    redirect_back_or_default (current_user ? prediction_menu_link : root_url)
  end

  def new
    @op_setting = OperationSetting.first#.is_under_maintenance?

    if @op_setting.is_under_maintenance?
      flash[:alert] = "It is not possible to sign in to Contestadors right now, due to maintenance. Please check back later."
    else
      @user_session = UserSession.new
    end
  end

  def create
    op_setting = OperationSetting.first
      
    if op_setting.is_under_maintenance? and (params.nil? or params[:user_session].nil? or op_setting.admin_user != params[:user_session][:email])      
      redirect_to "/maintenance.html"
      return
    end 
    @user_session = UserSession.new(params[:user_session])

    if @user_session.save

      #if @user_session.new_registration?
      #  flash[:notice] = "Welcome! As a new user, please review your registration details before continuing.."
      #  redirect_back_or_default edit_user_path( :current )
      #else

        #if @user_session.registration_complete?
          session[:selected_tournament_id] = Configuration::Contest.last.id

          #flash[:notice] = (session[:return_to] ? session[:return_to].to_s : " return to not set ") + (before_contest_participation_ends ? " is before contest participation ends" : " is after contest participation ends")

          if before_contest_participation_ends
            redirect_back_or_default prediction_menu_link
          else
            #contest = selected_contest
            #flash[:notice] = session[:selected_contest_id]
            #redirect_to (contest ? contest_instance_menu_link(contest) : prediction_menu_link)
            redirect_to prediction_menu_link
          end
        #else
        #  flash[:alert] = "Welcome back! Please complete required registration details before continuing.."
        #  redirect_back_or_default edit_user_path( :current )
        #end
      #end
    else
      flash[:alert] = "Failed to login or register."
      redirect_to new_user_session_path
    end
  end

  def destroy
    current_user_session.try(:destroy)
    session[:return_to] = nil
    redirect_to root_url
  end
end
