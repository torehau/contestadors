class CommentObserver < ActiveRecord::Observer
  def after_create(comment)

    #is_replay = !comment.parent.nil?
    contest_instance = ContestInstance.find(comment.commentable.id)
    
    if !comment.parent.nil?
      parent = comment.parent
      user = parent.user
      
      if user.id != comment.user.id and user.email_notifications_on_comments?
        CommentMailer.reply_on_your_comment(user, contest_instance, comment).deliver
      end
    else            
      
      if contest_instance and contest_instance.has_more_than_one_participants?
        contest_instance.participations.each do |participation|
        
          if participation and participation.send_email_notification_for?(comment)
            CommentMailer.new_comment_added(participation.user, contest_instance, comment).deliver        
          end
        end  
      end
    end    
  end
end
