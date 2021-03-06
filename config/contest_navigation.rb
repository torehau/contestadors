SimpleNavigation::Configuration.run do |navigation|
  navigation.items do |contest|
    contest_tabnav_items.each do |menu_item|
      contest.item menu_item[:label].to_sym, menu_item[:label], menu_item[:path], :highlights_on => lambda { menu_item[:highlight_conditions].index{|hc| hc.matches params} }    # menu_item[:highlight_conditions].each {|condition| t.highlights_on condition}
    end
  end
end