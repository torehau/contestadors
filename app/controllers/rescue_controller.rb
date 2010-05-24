class RescueController < ApplicationController

  def index
    msg = "Unknown path: "
    msg += " host => " + request.host if request.host
    msg += " host => " + request.path if request.path
    msg += " host => " + request.env['HTTP_REFERER'] if request.env['HTTP_REFERER']
    handle_faulty_url(Exception.new(msg))
  end
end
