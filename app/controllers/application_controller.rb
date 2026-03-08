class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # pre-action hooks around authentication and session management
  before_action :require_authentication
  before_action :check_session_expiry

  helper_method :authenticated?

  private

  def authenticated?
    session[:user_id].present?
  end

  def require_authentication
    redirect_to root_path, alert: "Please log in." unless session[:user_id]
  end

  def check_session_expiry
    return unless session[:expires_at]
    if Time.now.to_i > session[:expires_at]
      sign_out
      redirect_to root_path, alert: "Your session has expired. Please log in again."
    end
  end

  def sign_out
    reset_session
  end
end
