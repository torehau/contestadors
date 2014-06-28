class CommentMailer < ActionMailer::Base
  default :from => "no-reply@contestadors.com"
  
  def new_comment_added(user, contest_instance, comment)
    @user = user
    @contest_instance = contest_instance 
    @comment = comment
    mail(:to => user.email, :subject =>  "#{comment.user.name} added a new comment for the #{contest_instance.name} contest at Contestadors")
  end  
  
  def reply_on_your_comment(user, contest_instance, comment)
    @user = user
    @contest_instance = contest_instance 
    @comment = comment
    mail(:to => user.email, :subject =>  "#{comment.user.name} replied to your comment for the #{contest_instance.name} contest at Contestadors")
  end  
end
