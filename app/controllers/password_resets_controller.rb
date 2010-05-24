class PasswordResetsController < ApplicationController
  before_filter :require_no_user
  before_filter :load_user_using_perishable_token, :only => [:edit, :update]

  def new
    render
  end

  def create
    @user = User.find_by_email(params[:email])
    if @user
      @user.deliver_password_reset_instructions!
      flash[:notice] = "Instructions to reset your password have been emailed to you. Please check your email."
      redirect_to root_url
    else
      flash[:alert] = "No user was found with that email address."
      render :action => :new
    end
  end

  def edit
    render
  end

  def update
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]#:confirm_password ?
    
    if @user.save
      flash[:notice] = "Password successfully updated."
      redirect_to edit_account_path
    else
      render :action => :edit
    end
  end

private

  def load_user_using_perishable_token
    @user = User.find_using_perishable_token(params[:id])
    unless @user
      flash[:notice] = "Your account could not be retrieved. " +
        "Please try to copy and paste the URL " +
        "from your email into your browser or repeate the " +
        "reset password process."
      redirect_to root_url
    end
  end
end
