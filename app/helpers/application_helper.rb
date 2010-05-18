# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def footer_div_class
    if current_controller.eql?("predictions") and @aggregate_root_type.eql?("group")
      "footer-1"
    else
      "footer-2"
    end
  end

  def contest_instance_menu_link(contest_instance)
    if before_contest_participation_ends
      contest_participants_path(:contest => contest_instance.contest.permalink,
        :role => contest_instance.role_for(current_user),
        :contest_id => contest_instance.permalink,
        :uuid => contest_instance.uuid)
    else
      contest_path(:contest => contest_instance.contest.permalink,
        :role => contest_instance.role_for(current_user),
        :id => contest_instance.permalink,
        :uuid => contest_instance.uuid)
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

  def toggle_value(object, url)
    remote_function(:url => url, :method => :put,
                    :before => "Element.show('spinner-#{object.id}')",
                    :after => "Element.hide('spinner-#{object.id}')",
                    :with => "this.name + '=' + this.checked")
  end
end
