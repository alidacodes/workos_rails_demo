require "test_helper"

class WorkosApiAdapterTest < ActiveSupport::TestCase
  setup do
    @mock_profile = OpenStruct.new(
      id: "user_123",
      first_name: "John",
      last_name: "Doe",
      email: "john@example.com",
      organization_id: WorkosApiAdapter::ORGANIZATION_ID
    )
    @mock_token_response = OpenStruct.new(
      profile: @mock_profile,
      access_token: build_jwt(exp: (Time.now + 1.hour).to_i)
    )

    @mock_directory = OpenStruct.new(
      id: "dir_1",
      name: "Acme Corp",
      type: "okta",
      created_at: "2024-01-15T10:30:00.000Z",
      updated_at: "2024-02-20T14:45:00.000Z"
    )
    @mock_dir_list = OpenStruct.new(data: [ @mock_directory ])

    @mock_user = OpenStruct.new(
      id: "usr_1",
      first_name: "Alice",
      last_name: "Smith",
      email: "alice@example.com",
      groups: [],
      state: "active"
    )
    @mock_metadata = OpenStruct.new(before: nil, after: "cursor_abc")
    @mock_user_list = OpenStruct.new(data: [ @mock_user ], list_metadata: @mock_metadata)
  end

  # auth_url

  test "auth_url returns the WorkOS authorization URL" do
    stub_method(WorkOS::SSO, :authorization_url, "https://auth.workos.com/sso") do
      assert_equal "https://auth.workos.com/sso", WorkosApiAdapter.auth_url
    end
  end

  # callback

  test "callback returns profile and integer expires_at on success" do
    stub_method(WorkOS::SSO, :profile_and_token, @mock_token_response) do
      result = WorkosApiAdapter.callback("valid_code")
      assert_equal @mock_profile, result[:profile]
      assert_instance_of Integer, result[:expires_at]
      assert_in_delta (Time.now + 1.hour).to_i, result[:expires_at], 5
    end
  end

  test "callback raises UnauthorizedError when organization ID does not match" do
    wrong_profile = OpenStruct.new(@mock_profile.to_h.merge(organization_id: "wrong_org_id"))
    wrong_response = OpenStruct.new(profile: wrong_profile, access_token: "header.payload.sig")
    stub_method(WorkOS::SSO, :profile_and_token, wrong_response) do
      assert_raises(WorkosApiAdapter::UnauthorizedError) do
        WorkosApiAdapter.callback("valid_code")
      end
    end
  end

  test "callback falls back to 1 hour expiry when JWT is malformed" do
    bad_response = OpenStruct.new(profile: @mock_profile, access_token: "not-a-jwt")
    stub_method(WorkOS::SSO, :profile_and_token, bad_response) do
      result = WorkosApiAdapter.callback("valid_code")
      assert_in_delta (Time.now + 1.hour).to_i, result[:expires_at], 5
    end
  end

  test "callback falls back to 1 hour expiry when JWT has no exp claim" do
    no_exp_token = build_jwt_without_exp
    no_exp_response = OpenStruct.new(profile: @mock_profile, access_token: no_exp_token)
    stub_method(WorkOS::SSO, :profile_and_token, no_exp_response) do
      result = WorkosApiAdapter.callback("valid_code")
      assert_in_delta (Time.now + 1.hour).to_i, result[:expires_at], 5
    end
  end

  # list_directories

  test "list_directories returns normalized OpenStructs" do
    stub_method(WorkOS::DirectorySync, :list_directories, @mock_dir_list) do
      dirs = WorkosApiAdapter.list_directories
      assert_equal 1, dirs.length
      dir = dirs.first
      assert_equal "dir_1", dir.id
      assert_equal "Acme Corp", dir.name
      assert_equal "okta", dir.type
      assert_match(/January \d+, 2024 \d+:\d+/, dir.created_at)
      assert_match(/February \d+, 2024 \d+:\d+/, dir.updated_at)
    end
  end

  test "list_directories returns empty array when there are no directories" do
    stub_method(WorkOS::DirectorySync, :list_directories, OpenStruct.new(data: [])) do
      assert_equal [], WorkosApiAdapter.list_directories
    end
  end

  # fetch_directory_user_list

  test "fetch_directory_user_list returns normalized users and metadata" do
    stub_method(WorkOS::DirectorySync, :list_users, @mock_user_list) do
      result = WorkosApiAdapter.fetch_directory_user_list(directory_id: "dir_1")
      assert_equal 1, result[:users].length
      user = result[:users].first
      assert_equal "usr_1", user.id
      assert_equal "Alice", user.first_name
      assert_equal "Smith", user.last_name
      assert_equal "alice@example.com", user.email
      assert_equal [], user.groups
      assert_equal "active", user.state
      assert_equal @mock_metadata, result[:list_metadata]
    end
  end

  test "fetch_directory_user_list succeeds with nil after and before" do
    stub_method(WorkOS::DirectorySync, :list_users, @mock_user_list) do
      result = WorkosApiAdapter.fetch_directory_user_list(directory_id: "dir_1", after: nil, before: nil)
      assert_equal 1, result[:users].length
    end
  end

  test "fetch_directory_user_list succeeds with after cursor" do
    stub_method(WorkOS::DirectorySync, :list_users, @mock_user_list) do
      result = WorkosApiAdapter.fetch_directory_user_list(directory_id: "dir_1", after: "cursor_abc")
      assert_equal 1, result[:users].length
    end
  end

  test "fetch_directory_user_list succeeds with before cursor" do
    stub_method(WorkOS::DirectorySync, :list_users, @mock_user_list) do
      result = WorkosApiAdapter.fetch_directory_user_list(directory_id: "dir_1", before: "cursor_abc")
      assert_equal 1, result[:users].length
    end
  end

  private

  def build_jwt(exp:)
    payload = Base64.urlsafe_encode64({ "exp" => exp }.to_json, padding: false)
    "header.#{payload}.signature"
  end

  def build_jwt_without_exp
    payload = Base64.urlsafe_encode64({ "sub" => "user_123" }.to_json, padding: false)
    "header.#{payload}.signature"
  end
end
