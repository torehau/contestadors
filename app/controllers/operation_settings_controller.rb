class OperationSettingsController < ApplicationController
  strip_tags_from_params :only =>  [:create]
  before_filter :require_contestadors_admin_user
  
  def index
  end

  def create
    @op_settings.is_under_maintenance = params[:operation_setting][:is_under_maintenance]
    @op_settings.save!
    render :action => :index
  end  
end
