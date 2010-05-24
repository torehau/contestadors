module ContestAccessChecker
  protected

  def require_admin
    unless current_user.is_admin_of?(@contest_instance)
      unless current_user.is_participant_of?(@contest_instance)

        unauthorized = @contest_instance.id + ", " + @contest_instance.uuid
        @contest_instance = selected_contest
        unless current_user.is_admin_of?(@contest_instance)
          raise current_user.name + " attempted to access unauthorized contest: " + unauthorized
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
