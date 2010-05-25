class RescueController < ApplicationController

  def index
    msg = "Unknown path: "
    msg += " host => " + request.host if request.host
    msg += " path => " + request.path if request.path
    msg += " http referer => " + request.env['HTTP_REFERER'] if request.env['HTTP_REFERER']
    handle_faulty_url(Exception.new(msg))
  end
end
