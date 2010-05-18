module InvitationsHelper
  def add_invitation_link(name)
    link_to_function name do |page|
      page.insert_html :bottom, :contest_invitations, :partial => 'contest_invitation', 
        :object => Invitation.new(:name => "New Participant Name", :email => "participant@email.com")
    end
  end

  def contest_invitation_div_class(contest_invitation)
    return "invalid_contest_invitation" if contest_invitation.invalid?
    "contest_invitation"
  end

  def received_invitations_tabnav_items
    [{:label => "New",
      :tip => "New invitations to join contests",
      :path => pending_invitations_path(@contest.permalink),
      :highlight_conditions => [{:controller => "invitations", :action => "pending"}]},
     {:label => "Accepted",
      :tip => "Already accepted invitations",
      :path => accepted_invitations_path(@contest.permalink),
      :highlight_conditions => [{:controller => "invitations", :action => "accepted"}]}
    ]
  end

  def successful_invitation_acceptance_message(contest, instance)
    # contests_path(@contest.permalink, "member")
    "You have now successfully accepted the invitation and joined the #{link_to(instance.name, contest_instance_menu_link(instance))} contest."
  end

  def invitations_counter(total_entries, page)
    return total_entries.to_s unless page
    first = (page-1)*10 + 1
    interval_last = page*10
    last = total_entries <= interval_last ? total_entries : interval_last
    first.to_s + '-' + last.to_s + ' / ' + total_entries.to_s
  end
end
