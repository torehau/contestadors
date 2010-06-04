module ContestAccessChecker
  protected

  def require_admin
    unless current_user.is_admin_of?(@contest_instance)
      unless current_user.is_participant_of?(@contest_instance)

        @contest_instance = selected_contest
        unless current_user.is_admin_of?(@contest_instance)
          raise "User id: " + current_user.id.to_s + " attempted to access unauthorized contest."
        end
      end
    end
  end
  
  def require_participation
    unless current_user.is_participant_of?(@contest_instance)
      @contest_instance = selected_contest
    end
  end
end
