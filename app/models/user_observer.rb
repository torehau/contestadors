class UserObserver < ActiveRecord::Observer
  def after_create(user)
    Invitation.sync_existing_invitations_for(user)
  end

  def after_update(user)
    Invitation.sync_existing_invitations_for(user)
  end
end
