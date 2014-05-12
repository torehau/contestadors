class TournamentsController < ApplicationController
  before_filter :require_user

  def index
    @tournaments = Configuration::Contest.all
    @selected = session[:selected_tournament_id] ?
        Configuration::Contest.find(session[:selected_tournament_id]) :
        Configuration::Contest.where("available_to >= :now AND available_from <= :now", {:now => Time.now}).first

    @tournaments_grid = initialize_grid(Configuration::Contest,
      :conditions => {:id => @tournaments},
      :order => 'configuration_contests.created_at',
      :order_direction => 'desc',
      :per_page => 10
    )
  end

  def completed
    @tournaments = Configuration::Contest.where("available_to <= :now", {:now => Time.now})
    @selected = session[:selected_tournament_id] ?  Configuration::Contest.find(session[:selected_tournament_id]) : nil
    @tournaments_grid = initialize_grid(Configuration::Contest,
      :conditions => {:id => @tournaments},
      :order => 'configuration_contests.created_at',
      :order_direction => 'desc',
      :per_page => 10
    )
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

    if current_action_new "completed"
      redirect_to :completed
    else
      redirect_to :index
    end
  end
end
