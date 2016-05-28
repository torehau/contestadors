# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  window_title "Free Soccer Tournament Prediction Contests"
  helper :all # include all helpers, all the time
  helper_method :current_user_session, :current_user, :current_controller_new, :current_action_new, :current_tournament, :selected_tournament, :is_current_tournament_selected, :include_tournaments_menu_item, :matches_current_context, :current_aggregate_root_type, :current_aggregate_root_id, :selected_contest, :save_to_session, :before_contest_participation_ends, :after_contest_participation_ends, :prediction_menu_link, :contest_instance_menu_link, :is_under_maintenance, :redirect_if_under_maintenance, :is_contestadors_admin_user, :require_contestadors_admin_user
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  rescue_from Exception, :with => :handle_generic_error
  rescue_from NoMethodError, :with => :handle_faulty_url

private
    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = UserSession.find
    end

    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.record
    end

    def current_controller_new(controller)
      controller == params[:controller]
    end

    def current_action_new(actions=[])
      actions.include? params[:action]
    end

    def current_tournament
      Configuration::Contest.where("available_to >= :now AND available_from <= :now", {:now => Time.now}).first
    end
    
    def selected_tournament
      if session[:selected_tournament_id]
        return Configuration::Contest.find(session[:selected_tournament_id])    
      elsif params[:contest]
        return Configuration::Contest.where(:permalink => params[:contest]).last
      end
      current_tournament
    end
    
    def is_current_tournament_selected
      current_tournament and selected_tournament and current_tournament.id == selected_tournament.id
    end

    def include_tournaments_menu_item
      #Configuration::Contest.count > 3
      current_user.has_participated_in_previous_contests?
    end

    def matches_current_context(always_conditions, conditions_before_prediction_ends = [], conditions_after_prediction_ends = [])
      is_conditions_matched? always_conditions or is_conditions_matched? conditions_before_prediction_ends or is_conditions_matched? conditions_before_prediction_ends
    end

    def is_conditions_matched?(conditions)
      conditions.length > 0 and conditions.index{|hc| hc.matches params}
    end

    def current_aggregate_root_type
      params[:aggregate_root_type]
    end

    def current_aggregate_root_id
      params[:aggregate_root_id]
    end

    def require_contest
      return false unless defined?(@contest)
    end

    def before_contest_participation_ends
      @contest ||= selected_tournament
      Time.now < @contest.participation_ends_at
    end

    def after_contest_participation_ends
      @contest ||= selected_tournament
      Time.now > @contest.participation_ends_at
    end

    def selected_contest
      session_contest_instance = get_contest_instance_from_session
      return session_contest_instance if is_visible_for_current_user?(session_contest_instance)
      default_contest = current_user.default_contest
      save_to_session(default_contest)
      default_contest
    end

    def save_to_session(contest_instance)
      session[:selected_contest_id] = contest_instance.id.to_s if is_visible_for_current_user?(contest_instance)
    end

    def is_visible_for_current_user?(contest_instance)
      contest_instance and contest_instance.is_available_for?(current_user)
    end

#    def url_for_current_user
##      if current_user
#        url_params = current_user.prediction_summary.url_params
#        return predictions_url(url_params[:aggregate_root_type], url_params[:aggregate_root_type])
##      end
#    end

    def is_under_maintenance
      OperationSetting.first.is_under_maintenance?
    end
    
    def redirect_if_under_maintenance
      op_setting = OperationSetting.first
      
      if op_setting.is_under_maintenance? and (current_user.nil? or op_setting.admin_user != current_user.email)
        redirect_to "/maintenance.html"
        return false
      end      
    end
    
    def is_contestadors_admin_user
      op_setting = OperationSetting.first
      not current_user.nil? and op_setting.admin_user == User.find(current_user.id).email      
    end
    
    def require_contestadors_admin_user
      @op_settings = OperationSetting.first
      
      if current_user.nil? or @op_settings.admin_user != current_user.email
        redirect_back_or_default current_user ? prediction_menu_link : root_url
        return false
      end
    end

    def require_user
      unless current_user
        store_location
        flash[:notice] = render_to_string(:partial => 'shared/you_must_be_signed_in_message')
        redirect_to new_user_session_url
        return false
      end
    end

    def require_no_user
      if current_user
        store_location
        redirect_to edit_account_url
        return false
      end
    end

    def store_location
      session[:return_to] = request.request_uri
      #cookies[:return_to] = request.request_uri
    end

    def redirect_back_or_default(default)
      if cookies[:return_to]
        redirect_to cookies[:return_to]
        cookies[:return_to] = nil
      else
        redirect_to(session[:return_to] || default)
        session[:return_to] = nil
      end
    end

    def get_contest_instance_from_session
      if session[:selected_contest_id] and ContestInstance.exists?(session[:selected_contest_id].to_i)
        return ContestInstance.find(session[:selected_contest_id].to_i)
      end
      nil
    end

  def prediction_menu_link(contest_permalink="euro",aggregate_root_type="group",aggregate_root_id="A")
    @contest = selected_tournament#Configuration::Contest.where(:permalink => contest_permalink).last

    if before_contest_participation_ends
      new_prediction_path(contest_permalink,aggregate_root_type,aggregate_root_id)
    else
      user_predictions_path(contest_permalink,aggregate_root_type,aggregate_root_id)
    end
  end

  def contest_instance_menu_link(contest_instance)
    if before_contest_participation_ends
      if (current_user.is_participant_of?(contest_instance))
        contest_participants_path(:contest => contest_instance.contest.permalink,
          :role => contest_instance.role_for(current_user),
          :contest_id => contest_instance.permalink,
          :uuid => contest_instance.uuid)
      else
        contest_join_path(:contest => contest_instance.contest.permalink,
                                  :role => "member",
                                  :id => contest_instance.permalink,
                                  :uuid => contest_instance.uuid)
      end
    else
      contest_score_table_path(:contest => contest_instance.contest.permalink,
        :role => contest_instance.role_for(current_user),
        :contest_id => contest_instance.permalink, :uuid => contest_instance.uuid)
    end
  end

  def handle_generic_error(exception)
    flash[:alert] = "An error occured when handling your request. We will look at the problem shortly. "
    notify_hoptoad(exception)
    redirect_to (current_user ? edit_account_path : root_path)
  end

  def handle_faulty_url(exception)
    flash[:alert] = "An error occured when handling your request. The provided url was not recognized."
    notify_hoptoad(exception)
    Rails.logger.warn " **** Exception caught: " + exception.to_s
    redirect_to (current_user ? edit_account_path : root_path)
  end
end
