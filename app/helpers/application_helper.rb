# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def footer_div_class
    if current_controller.eql?("predictions") and @aggregate_root_type.eql?("group")
      "footer-1"
    else
      "footer-2"
    end
  end
end
