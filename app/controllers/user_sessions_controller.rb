class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy

  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      # TODO instead of hard-coding the url here, use a helper that fetches the appropriate url
      # based on time, available contests etc.
      redirect_back_or_default prediction_menu_link
    else
      flash.now[:alert] = "Email or password not valid. Please try again."
      render :action => :new
    end
  end

  def destroy
    current_user_session.destroy
#    redirect_back_or_default root_url
    session[:return_to] = nil
    redirect_to root_url
  end
end
