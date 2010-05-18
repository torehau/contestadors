class HomeController < ApplicationController
  before_filter :set_context_from_request_params, :if => :current_user

protected

  def set_context_from_request_params
    @contest = Configuration::Contest.find(:first)
  end
end
