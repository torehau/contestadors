class TournamentsController < ApplicationController
  before_filter :require_user

  def index    
    @tournaments = current_user.participating_in_tournaments
    @selected = session[:selected_tournament_id] ?
        Configuration::Contest.find(session[:selected_tournament_id]) :
        Configuration::Contest.where("available_to >= :now AND available_from <= :now", {:now => Time.now}).first

    @tournaments_grid = initialize_grid(Configuration::Contest,
      :conditions => {:id => @tournaments},
      :order => 'configuration_contests.created_at',
      :order_direction => 'desc',
      :per_page => 10
    )
    set_notice_message
  end

  def completed
    @tournaments = current_user.participating_in_tournaments.where("available_to <= :now", {:now => Time.now})
    @selected = session[:selected_tournament_id] ?  Configuration::Contest.find(session[:selected_tournament_id]) : nil
    @tournaments_grid = initialize_grid(Configuration::Contest,
      :conditions => {:id => @tournaments},
      :order => 'configuration_contests.created_at',
      :order_direction => 'desc',
      :per_page => 10
    )
    set_notice_message
  end

  def upcoming
    @tournaments = Configuration::Contest.where("available_from >= :now", {:now => Time.now})
    @tournaments_grid = initialize_grid(Configuration::Contest,
      :conditions => {:id => @tournaments},
      :order => 'configuration_contests.created_at',
      :order_direction => 'desc',
      :per_page => 10
    )
  end

  def select
    session[:selected_tournament_id] = params[:id]
    contest_instances = current_user.instances_of(selected_tournament, :all)
    
    if (contest_instances.count == 1)
      redirect_to contest_instance_menu_link(contest_instances.first)
    else
      redirect_to contests_path(selected_tournament.permalink, "all")
    end
  end
  
protected

  def set_notice_message
    if @selected.nil? or @selected.id == current_tournament.id
      flash.now[:notice] = "Select a previous tournament to see the results of the contests you participated in, and the Contestadors High Score List"
    else
      flash.now[:notice] = "You have currently selected the '"  + @selected.name + "' tournament."
    end  
  end  
end
