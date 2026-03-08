require_relative "../lib/adapters/workos_api_adapter"

class DirectoriesController < ApplicationController
  def index
    @directories = WorkosApiAdapter.list_directories
  end

  def show
    result = WorkosApiAdapter.fetch_directory_user_list(
      directory_id: params[:id],
      limit: 25,
      after: params[:after],
      before: params[:before]
    )
    @name = params[:name]
    @users = result[:users]
    @list_metadata = result[:list_metadata]
  end
end
