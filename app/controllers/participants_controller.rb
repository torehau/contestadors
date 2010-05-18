class ParticipantsController < ApplicationController
  before_filter :require_user
  before_filter :set_context_from_request_params
  before_filter :after_contest_participation_ends, :only => :update
  before_filter :require_admin, :only => :update

  def index
    session[:selected_contest_id] = @contest_instance.id.to_s if @contest_instance
    
    @participants_grid = initialize_grid(Participation,
      :include => [:user],
      :conditions => {:contest_instance_id => @contest_instance.id},
      :order => 'participations.created_at',
      :order_direction => 'desc',
      :per_page => 10
    )
  end

  def update
    @participation = Participation.find(params[:id])

    respond_to do |format|
      if @participation.update_attributes(params[:participation])
#        flash[:notice] = "Participant active state successfully changed."
        format.html {redirect_to contest_participants_path(:contest => @contest.permalink, :role => "admin", :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid)}
#        format.xml { head :ok}
        format.js { head :ok}
      else
        format.html {redirect_to contest_participants_path(:contest => @contest.permalink, :role => "admin", :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid)}
#        format.xml { head :ok}
        format.js { head :unprocessable_entity}
      end
    end
  end

protected

  def set_context_from_request_params
    @contest = Configuration::Contest.find_by_permalink(params[:contest])
    @role = params[:role]
    @contest_instance = ContestInstance.find_by_permalink_and_uuid(params[:contest_id], params[:uuid])
  end

  def require_admin
    current_user.is_admin_of?(@contest_instance)
  end
end
