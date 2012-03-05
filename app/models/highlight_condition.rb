class HighlightCondition

  attr_accessor :controller, :action, :role

  def initialize(controller, action = nil, role = nil)
    @controller = controller
    @action = action
    @role = role
  end

  def matches(request_params = {})
    @controller == request_params[:controller] and (!@action or @action == request_params[:action]) and (!@role or @role == request_params[:role])
  end
end