SimpleNavigation::Configuration.run do |navigation|
  navigation.items do |invitations|
    invitations.item :invitations, "Pending", pending_invitations_path(current_tournament.permalink), :highlights_on => lambda { current_action_new 'pending' }
    invitations.item :invitations, "Accepted", accepted_invitations_path(current_tournament.permalink), :highlights_on => lambda { current_action_new 'accepted' }
  end
end