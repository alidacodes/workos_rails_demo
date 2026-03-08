require_relative "../lib/adapters/workos_api_adapter"

class DirectoriesController < ApplicationController
  def index
    @directories = WorkosApiAdapter.list_directories
  end

  def show
    @directory = WorkosApiAdapter.fetch_directory(params[:id])
  end
end
