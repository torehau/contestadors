class InvitationMailer < ActionMailer::Base
  default :from => "no-reply@contestadors.com"
  
  def invite_existing_user(invitation)
    invitation_message(invitation)
  end

  def invite_new_user(invitation)
    invitation_message(invitation)
  end

private

  def invitation_message(invitation)
    @invitation = invitation
    #content_type "text/html"
    mail(:to => invitation.email, :subject =>  "#{invitation.sender.name} invites you to join a prediction contest at Contestadors")
  end

  #def invitation_message(invitation)
  #  subject    "#{invitation.sender.name} invites you to join a prediction contest at Contestadors"
  #  recipients invitation.email
  #  from       'no-reply@contestadors.com'
  #  sent_on    Time.now
  #  body       :invitation => invitation
  #  content_type "text/html"
  #end
end
