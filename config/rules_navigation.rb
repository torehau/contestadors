SimpleNavigation::Configuration.run do |navigation|
  navigation.items do |rules|
    rules.item :rules, "Predictions", predictions_rules_path(current_tournament.permalink), :highlights_on => lambda { current_action_new 'predictions' }
    rules.item :rules, "Contests", prediction_contests_rules_path(current_tournament.permalink), :highlights_on => lambda { current_action_new 'prediction_contests' }
    rules.item :rules, "Score Calculations", score_calculations_rules_path(current_tournament.permalink), :highlights_on => lambda { current_action_new 'score_calculations' }
  end
end