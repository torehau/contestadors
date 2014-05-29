SimpleNavigation::Configuration.run do |navigation|
  navigation.items do |account|
    account.item :general_settings, 'General Settings', edit_account_path, :highlights_on => lambda { current_action_new ['edit', 'update', 'show'] }
    account.item :change_password, 'Change Password', edit_password_path, :highlights_on => lambda { current_action_new ['edit_password', 'update_password'] }
    account.item :sign_in_options, 'Sign In Options', sign_in_options_path, :highlights_on => lambda { current_action_new ['sign_in_options'] }
  end
end
