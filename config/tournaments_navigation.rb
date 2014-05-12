SimpleNavigation::Configuration.run do |navigation|
  navigation.items do |tournaments|
    tournaments.item :tournaments, "All", tournaments_path, :highlights_on => lambda { current_action_new 'index' }
    tournaments.item :tournaments, "Completed", completed_tournaments_path, :highlights_on => lambda { current_action_new 'completed' }
    #tournaments.item :tournaments, "Upcoming", upcoming_tournaments_path, :highlights_on => lambda { current_action_new 'upcoming' }
  end
end
