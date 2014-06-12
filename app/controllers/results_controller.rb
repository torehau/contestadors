class ResultsController < ApplicationController
  strip_tags_from_params :only =>  [:update]
  before_filter :require_contestadors_admin_user
  
  def index
    upcomming_match_ids = Predictable::Championship::Match.upcomming.collect {|m| m.id}
	@upcomming_matchs_grid = initialize_grid(Predictable::Championship::Match,
		:include => [:home_team, :away_team],
		:conditions => {:id => upcomming_match_ids},
		:order => 'play_date',
		:order_direction => 'asc',
		:per_page => 10
	)     
  end

  def edit
    @match = Predictable::Championship::Match.find(params[:id])
  end
  
  def update
    @match = Predictable::Championship::Match.find(params[:id])
    @match.score = params[:predictable_championship_match][:home_team_score] + "-" + params[:predictable_championship_match][:away_team_score]
    @match.save!
    redirect_to results_url
  end
end
