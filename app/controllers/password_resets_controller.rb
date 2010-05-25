class PasswordResetsController < ApplicationController
  before_filter :require_no_user
  before_filter :load_user_using_perishable_token, :only => [:edit, :update]

  def new
    render
  end

  def create
    @user = User.find_by_email(params[:email])

    if @user

      if verify_recaptcha
        @user.deliver_password_reset_instructions!
        flash[:notice] = "Instructions to reset your password have been emailed to you. Please check your email."
        redirect_to root_url
        return
      end
    end
    flash[:alert] = "Unknown email og incorrect word verification response. Please try again."
    redirect_to :action => :new
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
      flash.now[:alert] = "Password reset failed."
      render :action => :edit
    end
  end

private

  def load_user_using_perishable_token
    @user = User.find_using_perishable_token(params[:id])
    unless @user
      flash.now[:alert] = "Your account could not be retrieved. " +
        "Try copy and paste the URL from your email into your browser or repeate the " +
        "reset password process."
      redirect_to root_url
    end
  end
end
