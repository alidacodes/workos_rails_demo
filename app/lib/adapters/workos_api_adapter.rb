module WorkosApiAdapter
  # authenticate via SSO
  def self.auth_url
    WorkOS::SSO.authorization_url(
      client_id: ENV.fetch("WORKOS_CLIENT_ID"),
      organization: ENV.fetch("WORKOS_ORGANIZATION_ID"),
      redirect_uri: ENV.fetch("WORKOS_REDIRECT_URI"),
    )
  end

  def self.callback(code)
    response = profile_and_token(code)
    profile = response.profile

    if profile.organization_id != ENV.fetch("WORKOS_ORGANIZATION_ID")
      raise UnauthorizedError, "Unauthorized: Organization ID does not match expected value"
    end

    { profile: profile, expires_at: token_expiry(response.access_token) }
  end

  private

  def self.profile_and_token(code)
    WorkOS::SSO.profile_and_token(
      client_id: ENV.fetch("WORKOS_CLIENT_ID"),
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