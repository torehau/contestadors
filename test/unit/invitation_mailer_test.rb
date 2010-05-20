require 'test_helper'

class InvitationMailerTest < ActionMailer::TestCase
  test "invite_existing_user" do
    @expected.subject = 'InvitationMailer#invite_existing_user'
    @expected.body    = read_fixture('invite_existing_user')
    @expected.date    = Time.now

    assert_equal @expected.encoded, InvitationMailer.create_invite_existing_user(@expected.date).encoded
  end

  test "invite_new_user" do
    @expected.subject = 'InvitationMailer#invite_new_user'
    @expected.body    = read_fixture('invite_new_user')
    @expected.date    = Time.now

    assert_equal @expected.encoded, InvitationMailer.create_invite_new_user(@expected.date).encoded
  end

end
