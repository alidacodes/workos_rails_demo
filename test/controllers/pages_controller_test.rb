require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get pages#home as root_path" do
    get root_path
    assert_response :success
  end
end
