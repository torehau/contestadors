Time::DATE_FORMATS[:month_and_year] = "%B %Y"
Time::DATE_FORMATS[:pretty] = lambda { |time| time.strftime("%a %e. %B %Y at %l:%M") + time.strftime("%p").downcase }
Time::DATE_FORMATS[:pretty_too] = "%d %B %Y, %H:%M"