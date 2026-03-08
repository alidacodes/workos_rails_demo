require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "home is accessible without authentication" do
    get root_url
    assert_response :success
  end

  test "home is accessible when authenticated" do
    login
    get root_url
    assert_response :success
  end
end
