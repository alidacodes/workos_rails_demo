require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  test "require_authentication redirects unauthenticated request to root" do
    get directories_url
    assert_redirected_to root_path
    assert_equal "Please log in.", flash[:alert]
  end

  test "require_authentication allows authenticated request through" do
    login
    stub_method(WorkosApiAdapter, :list_directories, []) do
      get directories_url
      assert_response :success
    end
  end

  test "check_session_expiry redirects when session is expired" do
    login
    travel_to(2.hours.from_now) do
      get directories_url
      assert_redirected_to root_path
      assert_equal "Your session has expired. Please log in again.", flash[:alert]
    end
  end

  test "check_session_expiry allows request when session is not expired" do
    login
    stub_method(WorkosApiAdapter, :list_directories, []) do
      get directories_url
      assert_response :success
    end
  end

  test "sign_out resets the session" do
    login
    delete logout_url
    get directories_url
    assert_redirected_to root_path
    assert_equal "Please log in.", flash[:alert]
  end
end
