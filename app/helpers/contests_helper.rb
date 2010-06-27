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
    
    if false#after_contest_participation_ends
      items << {:name => "Overview",
        :tip => "Contest overview and updates",
        :path => contest_path(:contest => @contest.permalink, :role => @role, :id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
        :highlight_conditions => [{:controller => "contests", :action => "show"}]}
    end
    items << {:name => "Score Table",
      :tip => "Ranking of the contest participants",
      :path => contest_score_table_path(:contest => @contest.permalink, :role => @role, :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
      :highlight_conditions => [{:controller => "score_tables", :action => "show"}]}
    items << {:name => "Participants",
      :tip => "All participants of the contest",
      :path => contest_participants_path(:contest => @contest.permalink, :role => @role, :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
      :highlight_conditions => [{:controller => "participants", :action => "index"}]}
  
    if current_user.is_admin_of?(@contest_instance)

      if @before_contest_participation_ends
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

      if @before_contest_participation_ends
        items << {:name => "Edit Contest",
                  :tip => "Rename contest or update invitation message",
                  :path => edit_contest_path(:contest => @contest.permalink,  :role => "admin", :id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
                  :highlight_conditions => [{:controller => "contests", :action => "edit"},
                                            {:controller => "contests", :action => "update"}]}
      end
    end
    unless @before_contest_participation_ends# and @participant_name
      items << {:name => "Latest Results",
        :tip => "Summery of the predictions placed by the contest participants for the latest settled matches ",
        :path => latest_results_path(:contest => @contest.permalink,  :role => "admin", :id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
        :highlight_conditions => [{:controller => "contests", :action => "latest_results"}]}

      items << {:name => "Upcoming Matches",
        :tip => "Summery of the predictions placed by the contest participants for the upcoming matches ",
        :path => upcoming_events_path(:contest => @contest.permalink,  :role => "admin", :id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
        :highlight_conditions => [{:controller => "contests", :action => "upcoming_events"}]}

      items << {:name => "Prediction Summary",
        :tip => "Summery of the predictions placed by a participant ",
        :path => prediction_summary_link(current_user.participations.of(@contest_instance)),
        :highlight_conditions => [{:controller => "participants", :action => "show"}]}
    end
    items
  end

  def objectives_meet_div_class(objectives_meet, predictable_item_processed)
    div_class = "objectives_meet"
    
    if predictable_item_processed
      div_class += "_" + objectives_meet.to_s
    end
    div_class
  end

  def knockout_stage_match_points_for(match, team)
    if team
      unless match.result
        "will receive #{match.total_possible_points.to_s} points if #{team.name} wins"
      else
        if match.winner_team.id.eql?(team.id)
          "received #{match.total_possible_points.to_s} points"
        else
          "recived no additional points for this team"
        end
      end
    else
      unless match.result
        "will not receive additional points for this match"
      else
        "received no additional points for this match"
      end
    end
  end
end
