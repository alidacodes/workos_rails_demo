class PagesController < ApplicationController
  before_action :require_authentication, except: [:home]
  def home
  end

  def directory
  end
end
