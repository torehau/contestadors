# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def not_signed_in_message
    "You must be signed in to access this page. Sign in with one of the options listed below to the right, or #{link_to('create a new Contestadors account ', new_account_path)}."
  end

  def prediction_summary_link(participation)
    participation ||= current_user.participations.of(@contest_instance)
    role ||= @contest_instance.role_for(current_user)
    query_params = {:contest => @contest.permalink,
                    :role => role, :contest_id => @contest_instance.permalink,
                    :uuid => @contest_instance.uuid}

    if participation #and participation.invitation
      query_params[:pid] = participation.id.to_s
    end
    participant_predictions_path(query_params)
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

  def button_to_link(name, link, options={})
    confirm_option = options.delete(:confirm)
    popup_option = options.delete(:popup)
    link_function = popup_option ? redirect_function(link,:new_window => true) : redirect_function(link)
    link_function = "if (confirm('#{escape_javascript(confirm_option)}')) { #{link_function}; }" if confirm_option
    button_to_function name, link_function, options
  end

  def redirect_function(location, options={})
    location = location.is_a?(String) ? location : url_for(location)
    if options[:new_window]
      %|window.open('#{location}')|
    else
      %|{window.location.href='#{location}'}|
    end
  end
end
