class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:show, :edit, :update, :edit_password, :update_password]
  before_filter :set_current_user, :except => [:new, :create]
  before_filter :set_context, :except => [:new, :create]

  def new
    @user = User.new
    
    if after_contest_participation_ends
      flash.now[:alert] = "It is for the moment not possible to register new user accounts."
    end
  end

  def create
    if after_contest_participation_ends
      redirect_to :action => "new"
    else 
	  @user = User.new(params[:user])
    
      if verify_recaptcha
    
        if @user.save
	      flash[:notice] = "Account registered!"
		  redirect_back_or_default account_url
		  flash.delete(:recaptcha_error)
          return
        else
          set_error_details
        end
      else
        @focused_field_id = "recaptcha_response_field"
        flash.now[:alert] = "Word verification response is incorrect, please try again."
      end
        flash.delete(:recaptcha_error)
        render :action => :new
    end
  end

  def show
    @user.valid?
    render :edit
  end

  def edit

    unless @user.valid?
      flash.now[:notice] = "Please complete the required registration details before continuing.."
    end
  end

  def update
    
    if @user.update_attributes(params[:user])
      flash.now[:notice] = "Account updated!"
    else
      set_error_details
    end
    render :action => :edit
  end

  # This action has the special purpose of receiving an update of the RPX identity information
  # for current user - to add RPX authentication to an existing non-RPX account.
  # RPX only supports :post, so this cannot simply go to update method (:put)
  def addrpxauth

    if @user.save
      flash[:notice] = "Successfully added RPX authentication for this account."
    else
      flash[:alert] = "Adding RPX authentication for this failed."
    end
    render :action => 'edit'
  end

  def sign_in_options
    @provider_names = @user.included_identity_providers
    render
  end
  
  def edit_password
    render
  end
  
  def update_password
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]#:confirm_password ?
    
    if @user.changed? and @user.save
      flash.now[:notice] = "Password successfully changed."
    else
      set_error_details
      flash.now[:alert] = "Password change failed."
    end
    render :action => "edit_password"
  end


private

  def set_current_user
    @user = current_user
  end
  
  def set_context
    @before_contest_participation_ends = before_contest_participation_ends
  end  

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
