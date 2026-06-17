module Api
  class AuthController < ApplicationController

    def token
      render json: ApsService.viewer_token
    end

  end
end