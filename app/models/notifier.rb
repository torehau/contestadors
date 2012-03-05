class Notifier < ActionMailer::Base
  default :from => "no-reply@contestadors.com"

  def password_reset_instructions(user)
    @user = user
    @edit_password_reset_url = edit_password_reset_url(user.perishable_token)
    #content_type "text/html"
    mail(:to => user.email, :subject => "Password Reset Instructions")
  end

  #def password_reset_instructions(user)
  #  subject    "Password Reset Instructions"
  #  recipients user.email
  #  from       'no-reply@contestadors.com'
  #  sent_on    Time.now
  #  body       :user => user, :edit_password_reset_url => edit_password_reset_url(user.perishable_token)
  #  content_type "text/html"
  #end

end
