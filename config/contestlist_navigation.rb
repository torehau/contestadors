SimpleNavigation::Configuration.run do |navigation|
  navigation.items do |contest|
    @contest_instances.each do |instance|
      contest.item :contest_instance, instance.name, contest_instance_menu_link(instance), :highlights_on => lambda { current_action_new ["index"]  if @contest_instance and instance.eql?(@contest_instance) }
    end
  end
end