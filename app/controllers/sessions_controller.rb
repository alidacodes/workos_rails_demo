require_relative "../lib/adapters/workos_api_adapter"
class SessionsController < ApplicationController
  skip_before_action :require_authentication, only: [:create, :callback]
  skip_before_action :check_session_expiry, only: [:create, :callback]

  def create
    redirect_to WorkosApiAdapter.auth_url, allow_other_host: true
  end

  def callback
    result = WorkosApiAdapter.callback(params[:code])
    session.update({
      user_id: result[:profile].id,
      user_first_name: result[:profile].first_name,
      user_last_name: result[:profile].last_name,
      user_email: result[:profile].email,
      expires_at: result[:expires_at]
    })
    redirect_to root_path, notice: "Successfully logged in with SSO. Welcome!"
  rescue WorkOS::APIError => e
    logger.error "WorkOS API error: #{e.message}"
    redirect_to root_path, alert: "Authentication failed. Please try again."
  rescue => e
    logger.error "Unexpected error in SSO callback: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    redirect_to root_path, alert: "An error occurred. Please contact support."
  end

  def destroy
    sign_out
    redirect_to root_path, notice: "Successfully logged out. See you next time!"
  end
end
