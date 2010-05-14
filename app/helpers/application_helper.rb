# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def footer_div_class
    if current_controller.eql?("predictions") and @aggregate_root_type.eql?("group")
      "footer-1"
    else
      "footer-2"
    end
  end

  # put this in the body after a form to set the input focus to a specific control id
  # at end of rhtml file: <%= set_focus_to_id 'form_field_label' %>
  def set_focus_to_id(id)
    javascript_tag("$('#{id}').focus()");
  end

  def countdown_field(field_id,update_id,max,options = {})
    function = "$('#{update_id}').innerHTML = (#{max} - $F('#{field_id}').length);"
    count_field_tag(field_id,function,options)
  end

  def count_field(field_id,update_id,options = {})
    function = "$('#{update_id}').innerHTML = $F('#{field_id}').length;"
    count_field_tag(field_id,function,options)
  end

  def count_field_tag(field_id,function,options = {})
    out = javascript_tag function
    options = {:frequency => 0.1, :function => function}.merge(options)
    out += observe_field(field_id, options)
    return out
  end
end
