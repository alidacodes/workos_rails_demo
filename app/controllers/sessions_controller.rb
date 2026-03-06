class SessionsController < ApplicationController
  skip_before_action :require_authentication, only: [:new, :create]
  skip_before_action :check_session_expiry, only: [:new, :create]

  def new

  end

  def create

  end
  
  def destroy

  end
end