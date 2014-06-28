module ContestsHelper
  def contests_main_menu_link
    if @before_contest_participation_ends
      new_contest_path(@contest.permalink, "admin")
    else
      contests_path(selected_tournament.permalink, "all")
    end
  end

  def contests_tabnav_items
    items = []

    if @before_contest_participation_ends
      items << {:label => "Create",
        :tip => "Create A New Prediction Contest for this tournament",
        :path => new_contest_path(@contest.permalink, "admin"),
        :highlight_conditions => [HighlightCondition.new("contests", "new", "admin"), HighlightCondition.new("contests", "create", "admin")]}
    end
    items << {:label => "All Existing",
      :tip => "All contests you participate in",
      :path => contests_path(@contest.permalink, "all"),
      :highlight_conditions => [HighlightCondition.new("contests", "index", "all")]}#[{:controller => "contests", :action => "index", :role => "all"}]},
    items << {:label => "Administrator",
      :tip => "Contests created and administrated by you",
      :path => contests_path(@contest.permalink, "admin"),
      :highlight_conditions => [HighlightCondition.new("contests", "index", "admin")]}#[{:controller => "contests", :action => "index", :role => "admin"}]},
    items << {:label => "Member",
      :tip => "Contests joined by invitations",
      :path => contests_path(@contest.permalink, "member"),
      :highlight_conditions => [HighlightCondition.new("contests", "index","member")]}#[{:controller => "contests", :action => "index", :role => "member"}]},
    items
  end

  #def params_context
  #  "Controller: " + params[:controller] + " Action: " + params[:action] + " Role: " + params[:role]
  #end

  def contest_tabnav_items
    items = []
    
    if false#after_contest_participation_ends
      items << {:label => "Overview",
        :tip => "Contest overview and updates",
        :path => contest_path(:contest => @contest.permalink, :role => @role, :id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
        :highlight_conditions => [HighlightCondition.new("contests", "show")]}
    end
    unless current_user.is_participant_of?(@contest_instance)
      if @before_contest_participation_ends
        items << {:label => "Join",
                  :tip => "Become a member of this contest",
                  :path => contest_join_path(:contest => @contest.permalink, :role => "member", :id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
                  :highlight_conditions => [HighlightCondition.new("contests", "join")]}
      end
    else
      items << {:label => "Score Table",
        :tip => "Ranking of the contest participants",
        :path => contest_score_table_path(:contest => @contest.permalink, :role => @role, :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
        :highlight_conditions => [HighlightCondition.new("score_tables", "show")]}
      if is_current_tournament_selected        
	    items << {:label => "Comments",
		  :tip => "Post comments for this contests ",
		  :path => contest_comments_path(:contest => @contest.permalink,  :role => "admin", :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
		  :highlight_conditions => [HighlightCondition.new("comments", "index"),
			  					    HighlightCondition.new("comments", "new"),
								    HighlightCondition.new("comments", "show")]}
	  end
      items << {:label => "Participants",
        :tip => "All participants of the contest",
        :path => contest_participants_path(:contest => @contest.permalink, :role => @role, :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
        :highlight_conditions => [HighlightCondition.new("participants", "index")]}

      if current_user.is_admin_of?(@contest_instance)

        if @before_contest_participation_ends
          items << {:label => "Invite",
                    :tip => "Invite people to join the contest",
                    :path => new_contest_invitation_path(:contest => @contest.permalink,  :role => "admin", :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
                    :highlight_conditions => [HighlightCondition.new("invitations", "new"),
                                              HighlightCondition.new("invitations", "copy"),
                                              HighlightCondition.new("invitations", "create")]}
        end
        items << {:label => "Invite History",
                  :tip => "A list of previously sent invitions",
                  :path => contest_invitations_path(:contest => @contest.permalink, :role => "admin", :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
                  :highlight_conditions => [HighlightCondition.new("invitations", "index")]}

        if @before_contest_participation_ends
          items << {:label => "Edit Contest",
                    :tip => "Rename contest or update invitation message",
                    :path => edit_contest_path(:contest => @contest.permalink,  :role => "admin", :id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
                    :highlight_conditions => [HighlightCondition.new("contests", "edit"),
                                              HighlightCondition.new("contests", "update")]}
        end
      end
      unless @before_contest_participation_ends# and @participant_name
        if is_current_tournament_selected
  		  items << {:label => "Latest Results",
		    :tip => "Summery of the predictions placed by the contest participants for the latest settled matches ",
		    :path => latest_results_path(:contest => @contest.permalink,  :role => "admin", :id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
		    :highlight_conditions => [HighlightCondition.new("contests", "latest_results")]}

		  items << {:label => "Upcoming Matches",
		    :tip => "Summery of the predictions placed by the contest participants for the upcoming matches ",
		    :path => upcoming_events_path(:contest => @contest.permalink,  :role => "admin", :id => @contest_instance.permalink, :uuid => @contest_instance.uuid),
		    :highlight_conditions => [HighlightCondition.new("contests", "upcoming_events")]}

		  items << {:label => "Prediction Summary",
		    :tip => "Summery of the predictions placed by a participant ",
		    :path => prediction_summary_link(current_user.participations.of(@contest_instance)),
		    :highlight_conditions => [HighlightCondition.new("participants", "show")]}
		    		    
        end
      end
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

  def knockout_stage_match_objective_descr(match)
    final_matches = {"Third Place" => "Third Place Play-off", "Final" => "Final"}

    unless final_matches.has_key?(match.description)
      "through to the " + match.stage.next.description
    else
      "as winner of the " + final_matches[match.description]
    end
  end
end
