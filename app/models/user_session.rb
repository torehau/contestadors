class UserSession < Authlogic::Session::Base
  rpx_key RPX_API_KEY

private

  def map_rpx_data
    self.attempted_record.send("#{klass.email_field}=", @rpx_data['profile']['email'] ) if attempted_record.send(klass.email_field).blank?

    # map some other columns explicitly
    self.attempted_record.name = @rpx_data['profile']['displayName'] if attempted_record.name.blank?
  end
end
