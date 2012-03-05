SimpleNavigation::Configuration.run do |navigation|
  navigation.items do |home|
    %w{about rules terms privacy contact faq}.each do |name|
      title = "faq".eql?(name) ? "FAQ" : name.capitalize
      home.item name.to_sym, title, home_path(name), :highlights_on => lambda { current_action? name }
    end
  end
end