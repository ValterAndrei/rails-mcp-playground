class HomeController < ApplicationController
  def index
    render json: { status: "ok", env: Rails.env, time: Time.current }
  end
end
