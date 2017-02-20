class WelcomeController < ApplicationController
  def index
    redirect_to pull_request_open_path
  end
end
