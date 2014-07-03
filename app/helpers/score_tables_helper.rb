module ScoreTablesHelper

  def add_or_view_comments_for_contests
    "Got something you would like to share with the other contest participants? #{link_to('Add a new comment', new_contest_comment_path(:contest => @contest.permalink,  :role => "admin", :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid))} or reply to #{link_to('existing comments for the contest', contest_comments_path(:contest => @contest.permalink,  :role => "admin", :contest_id => @contest_instance.permalink, :uuid => @contest_instance.uuid))}."
  end
end
