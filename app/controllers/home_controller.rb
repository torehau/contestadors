class HomeController < ApplicationController
  before_filter :redirect_if_under_maintenance
  before_filter :set_context_from_request_params, :if => :current_user

protected

  def set_context_from_request_params
    @contest = selected_tournament#Configuration::Contest.find(:first)
  end
end
