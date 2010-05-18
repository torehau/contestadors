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
    items = []
    
    if after_contest_participation_ends
      items << {:name => "Overview",
        :tip => "Contest overview and updates",
        :path => contest_path(:contest => @contest.permalink, :role => @role, :id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
        :highlight_conditions => [{:controller => "contests", :action => "show"}]}
    end
    items << {:name => "Participants",
      :tip => "All participants of the contest",
      :path => contest_participants_path(:contest => @contest.permalink, :role => @role, :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
      :highlight_conditions => [{:controller => "participants", :action => "index"}]}
  
    if current_user.is_admin_of?(@contest_instance)

      if before_contest_participation_ends
        items << {:name => "Invite",
                  :tip => "Invite people to join the contest",
                  :path => new_contest_invitation_path(:contest => @contest.permalink,  :role => "admin", :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
                  :highlight_conditions => [{:controller => "invitations", :action => "new"},
                                            {:controller => "invitations", :action => "create"}]}
      end
      items << {:name => "Invite History",
                :tip => "A list of previously sent invitions",
                :path => contest_invitations_path(:contest => @contest.permalink, :role => "admin", :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
                :highlight_conditions => [{:controller => "invitations", :action => "index"}]}

      if before_contest_participation_ends
        items << {:name => "Edit Contest",
                  :tip => "Rename contest or update invitation message",
                  :path => edit_contest_path(:contest => @contest.permalink,  :role => "admin", :id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
                  :highlight_conditions => [{:controller => "contests", :action => "edit"},
                                            {:controller => "contests", :action => "update"}]}
      end
    end
    items
  end
end
