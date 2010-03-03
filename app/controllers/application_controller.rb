# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  window_title "Free World Cup Prediction Contests"
  helper :all # include all helpers, all the time
  helper_method :current_user_session, :current_user, :current_controller, :current_action#, :url_for_current_user
  filter_parameter_logging :password, :password_confirmation
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  private
    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = Core::UserSession.find
    end

    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.record
    end

    def current_controller
      request.path_parameters['controller']
    end

    def current_action
      request.path_parameters['action']
    end

#    def url_for_current_user
##      if current_user
#        url_params = current_user.prediction_summary.url_params
#        return predictions_url(url_params[:aggregate_root_type], url_params[:aggregate_root_type])
##      end
#    end

    def require_user
      unless current_user
        store_location
        flash[:notice] = "You must be logged in to access this page"
        redirect_to new_user_session_url
        return false
      end
    end

    def require_no_user
      if current_user
        store_location
        flash[:notice] = "You must be logged out to access this page"
        redirect_to account_url
        return false
      end
    end

    def store_location
      session[:return_to] = request.request_uri
    end

    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end
end
