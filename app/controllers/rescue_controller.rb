class RescueController < ApplicationController

  def index
    handle_faulty_url
  end
end
