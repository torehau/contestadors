class RescueController < ApplicationController

  def index
    puts "Rescued unknown path: " + request.path
    handle_faulty_url
  end
end
