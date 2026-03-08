require "ostruct"

module WorkosApiAdapter
  CLIENT_ID = ENV.fetch("WORKOS_CLIENT_ID")
  ORGANIZATION_ID = ENV.fetch("WORKOS_ORGANIZATION_ID")
  REDIRECT_URI = ENV.fetch("WORKOS_REDIRECT_URI")
  # authenticate via SSO
  def self.auth_url
    WorkOS::SSO.authorization_url(
      client_id: CLIENT_ID,
      organization: ORGANIZATION_ID,
      redirect_uri: REDIRECT_URI,
    )
  end

  def self.callback(code)
    response = profile_and_token(code)
    profile = response.profile

    if profile.organization_id != ORGANIZATION_ID
      raise UnauthorizedError, "Unauthorized: Organization ID does not match expected value"
    end

    { profile: profile, expires_at: token_expiry(response.access_token) }
  end

  def self.list_directories
    # get directories for the environment's organization
    directories = WorkOS::DirectorySync.list_directories(organization_id: ORGANIZATION_ID)
    # normalize the result into simple objects with just the data we need for our app
    # see https://github.com/workos/workos-ruby/blob/main/lib/workos/types/list_struct.rb
    directories.data.map do |directory|
      OpenStruct.new(
        id: directory.id,
        name: directory.name,
        type: directory.type,
        created_at: Time.zone.parse(directory.created_at).strftime("%B %d, %Y %H:%M"),
        updated_at: Time.zone.parse(directory.updated_at).strftime("%B %d, %Y %H:%M")
      )
    end
  end

  def self.fetch_directory_user_list(directory_id:, limit: 25, after: nil, before: nil)
    params = { directory: directory_id, limit: limit }
    params[:after] = after if after
    params[:before] = before if before

    result = WorkOS::DirectorySync.list_users(**params)

    users = result.data.map do |user|
      OpenStruct.new(
        id: user.id,
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        groups: user.groups,
        state: user.state
      )
    end

    { users: users, list_metadata: result.list_metadata }
  end

  private

  def self.profile_and_token(code)
    WorkOS::SSO.profile_and_token(
      client_id: CLIENT_ID,
      code: code,
    )
  end

  def self.token_expiry(access_token)
    payload_b64 = access_token.split(".")[1]
    return 1.hour.from_now.to_i if payload_b64.nil?
    padding = (4 - payload_b64.length % 4) % 4
    JSON.parse(Base64.urlsafe_decode64(payload_b64 + "=" * padding))["exp"] || 1.hour.from_now.to_i
  rescue
    1.hour.from_now.to_i
  end
end
