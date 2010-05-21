class InvitationObserver < ActiveRecord::Observer
  
  def after_create(invitation)
    if invitation.existing_user
      InvitationMailer.deliver_invite_existing_user(invitation)
    else
      # TODO include in due time
      InvitationMailer.deliver_invite_new_user(invitation)
    end
    invitation.deliver!
  end
end
