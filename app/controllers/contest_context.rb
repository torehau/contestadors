module ContestContext
  protected

  def set_contest_context(permalink, role, contest_id, contest_uuid)
    @contest = Configuration::Contest.find_by_permalink(permalink)
    @role = role
    @contest_instance = ContestInstance.find_by_permalink_and_uuid(contest_id, contest_uuid)
  end
end
