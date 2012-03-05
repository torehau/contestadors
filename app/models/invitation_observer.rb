class InvitationObserver < ActiveRecord::Observer
  
  def after_create(invitation)
    if invitation.existing_user
      InvitationMailer.invite_existing_user(invitation).deliver
    else      
      InvitationMailer.invite_new_user(invitation).deliver
    end
    invitation.deliver!
  end
end
