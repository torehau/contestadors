require 'test_helper'

class TournamentsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get completed" do
    get :completed
    assert_response :success
  end

  test "should get upcomming" do
    get :upcoming
    assert_response :success
  end

end
