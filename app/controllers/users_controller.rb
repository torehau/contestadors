class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:show, :edit, :update]

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])

    if verify_recaptcha

      if @user.save
        flash[:notice] = "Account registered!"
        redirect_back_or_default account_url
        return
      else
        set_error_details
      end
    else
      @focused_field_id = "recaptcha_response_field"
      flash.now[:alert] = "Word verification response is incorrect, please try again."
    end
    render :action => :new
  end

  def show
    @user = current_user
    @user.valid?
    render :edit
  end

  def edit
    @user = current_user
    unless @user.valid?
      flash.now[:notice] = "Please complete the required registration details before continuing.."
    end
  end

  def update
    @user = current_user # makes our views "cleaner" and more consistent
    
    if @user.update_attributes(params[:user])
      flash.now[:notice] = "Account updated!"
    else
      set_error_details
    end
    render :action => :edit
  end

private

  def set_error_details
    if @user.errors.on(:name)
      flash.now[:alert] = "The name was not valid."
      @focused_field_id = "user_name"
    elsif @user.errors.on(:email)
      flash.now[:alert] = "The email is not valid. Incorrect format or already registered."
      @focused_field_id = "user_email"
    elsif @user.errors.on(:password)
      @focused_field_id = "user_password"
      err_msg = "The password "
      
      if @user.errors.on(:passord).is_a?(String)
        err_msg += @user.errors.on(:passord)
      elsif @user.errors.on(:passord).is_a?(Array)
        @user.errors.on(:passord).each{|error| err_msg += error + ", " }
      else
        err_msg += "is not valid."
      end
      flash.now[:alert] = err_msg
    elsif @user.errors.on(:password_confirmation)
      @focused_field_id = "password"
      err_msg = "The password "

      if @user.errors.on(:password_confirmation).is_a?(String)
        err_msg += @user.errors.on(:password_confirmation)
      elsif @user.errors.on(:password_confirmation).is_a?(Array)
        @user.errors.on(:password_confirmation).each{|error| err_msg += error + ", " }
      else
        err_msg += " is not valid. Confirmation does not match first entry."
      end
      flash.now[:alert] = err_msg
    end
  end
end
