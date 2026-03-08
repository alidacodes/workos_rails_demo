require "test_helper"

# Unauthenticated tests — no login setup
class DirectoriesControllerUnauthenticatedTest < ActionDispatch::IntegrationTest
  test "index redirects to root when not authenticated" do
    get directories_url
    assert_redirected_to root_path
    assert_equal "Please log in.", flash[:alert]
  end

  test "show redirects to root when not authenticated" do
    get directory_url(id: "dir_1")
    assert_redirected_to root_path
    assert_equal "Please log in.", flash[:alert]
  end
end

# Authenticated tests — login called in setup
class DirectoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    login
    @mock_dirs = [
      OpenStruct.new(
        id: "dir_1",
        name: "Acme Corp",
        type: "okta",
        created_at: "January 01, 2024 00:00",
        updated_at: "January 01, 2024 00:00"
      )
    ]
    @mock_users = [
      OpenStruct.new(
        id: "usr_1",
        first_name: "Alice",
        last_name: "Smith",
        email: "alice@example.com",
        groups: [],
        state: "active"
      )
    ]
    @mock_metadata = OpenStruct.new(before: nil, after: "cursor_abc")
    @mock_user_result = { users: @mock_users, list_metadata: @mock_metadata }
  end

  test "index returns success and lists directories" do
    stub_method(WorkosApiAdapter, :list_directories, @mock_dirs) do
      get directories_url
      assert_response :success
      assert_match "Acme Corp", response.body
    end
  end

  test "show returns success and lists users for a directory" do
    stub_method(WorkosApiAdapter, :fetch_directory_user_list, @mock_user_result) do
      get directory_url(id: "dir_1"), params: { name: "Acme Corp" }
      assert_response :success
      assert_match "Alice", response.body
    end
  end

  test "show handles pagination with after cursor" do
    stub_method(WorkosApiAdapter, :fetch_directory_user_list, @mock_user_result) do
      get directory_url(id: "dir_1"), params: { after: "cursor_abc" }
      assert_response :success
    end
  end

  test "show handles pagination with before cursor" do
    stub_method(WorkosApiAdapter, :fetch_directory_user_list, @mock_user_result) do
      get directory_url(id: "dir_1"), params: { before: "cursor_abc" }
      assert_response :success
    end
  end
end
