SimpleNavigation::Configuration.run do |navigation|
  navigation.items do |predictions|
    if @wizard
      @wizard.all_available_steps.each do |step|
        predictions.item :predictions, step.label, prediction_menu_link(@contest.permalink, step.type, step.id), :highlights_on => lambda { current_aggregate_root_id == step.id }
      end
    end
  end
end