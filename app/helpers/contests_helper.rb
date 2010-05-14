module ContestsHelper
  def contests_tabnav_items
    [{:label => "All",
      :tip => "All contests you participate in",
      :path => contests_path(@contest.permalink, "all"),
      :highlight_conditions => [{:controller => "contests", :action => "index", :role => "all"}]},
     {:label => "Administrator",
      :tip => "Contests created and administrated by you",
      :path => contests_path(@contest.permalink, "admin"),
      :highlight_conditions => [{:controller => "contests", :action => "index", :role => "admin"}]},
     {:label => "Member",
      :tip => "Contests joined by invitations",
      :path => contests_path(@contest.permalink, "member"),
      :highlight_conditions => [{:controller => "contests", :action => "index", :role => "member"}]},
    ]
  end

  def contest_tabnav_items
    items = [{:name => "Participants",
      :path => contest_path(:contest => @contest.permalink, :role => @role, :id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
      :highlight_conditions => [{:controller => "contests", :action => "show"}]}]
  
    if current_user.is_admin_of?(@contest_instance)
      items << {:name => "Invite",
                :path => new_contest_invitation_path(:contest => @contest.permalink,  :role => "admin", :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
                :highlight_conditions => [{:controller => "invitations", :action => "new"},
                                          {:controller => "invitations", :action => "create"}]}
      items << {:name => "Invite History",
                :path => contest_invitations_path(:contest => @contest.permalink, :role => "admin", :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
                :highlight_conditions => [{:controller => "invitations", :action => "index"}]}

      items << {:name => "Edit Contest",
                :path => edit_contest_path(:contest => @contest.permalink,  :role => "admin", :id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
                :highlight_conditions => [{:controller => "contests", :action => "edit"},
                                          {:controller => "contests", :action => "update"}]}
    end
    items
  end
end
