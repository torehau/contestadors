module HighScoreHelper

  def user_not_allow_name_in_high_score_list
    "You appear as 'Anonymous' in the High Score List. Update your #{link_to('Account information', edit_account_path)} if you want your name to be shown in this list (available to all users)."
  end
end
