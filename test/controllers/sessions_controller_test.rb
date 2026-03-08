require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "create redirects to WorkOS authorization URL" do
    stub_method(WorkosApiAdapter, :auth_url, "https://auth.workos.com/fake-sso") do
      get login_url
      assert_redirected_to "https://auth.workos.com/fake-sso"
    end
  end

  test "create is accessible without authentication" do
    stub_method(WorkosApiAdapter, :auth_url, "https://auth.workos.com/fake-sso") do
      get login_url
      assert_redirected_to "https://auth.workos.com/fake-sso"
      assert_no_match "Please log in.", flash[:alert].to_s
    end
  end

  test "callback sets session and redirects on successful authentication" do
    mock_profile = OpenStruct.new(
      id: "user_123",
      first_name: "John",
      last_name: "Doe",
      email: "john@example.com"
    )
    mock_result = { profile: mock_profile, expires_at: (Time.now + 1.hour).to_i }

    stub_method(WorkosApiAdapter, :callback, mock_result) do
      get auth_callback_url, params: { code: "auth_code_123" }
    end

    assert_redirected_to root_path
    assert_equal "Successfully logged in with SSO. Welcome!", flash[:notice]
    assert_equal "user_123", session[:user_id]
    assert_equal "john@example.com", session[:user_email]
    assert_equal "John", session[:user_first_name]
    assert_equal "Doe", session[:user_last_name]
    assert_instance_of Integer, session[:expires_at]
  end

  test "callback handles WorkOS::APIError" do
    stub_method(WorkosApiAdapter, :callback, ->(_code) { raise WorkOS::APIError.new(message: "Invalid code") }) do
      get auth_callback_url, params: { code: "invalid_code" }
    end

    assert_redirected_to root_path
    assert_equal "Authentication failed. Please try again.", flash[:alert]
  end

  test "callback handles unexpected StandardError" do
    stub_method(WorkosApiAdapter, :callback, ->(_code) { raise StandardError, "Server error" }) do
      get auth_callback_url, params: { code: "auth_code_123" }
    end

    assert_redirected_to root_path
    assert_equal "An error occurred. Please contact support.", flash[:alert]
  end

  test "destroy clears session and redirects with notice" do
    login
    assert_equal "user_123", session[:user_id]

    delete logout_url

    assert_redirected_to root_path
    assert_equal "Successfully logged out. See you next time!", flash[:notice]
    assert_nil session[:user_id]
  end
end
