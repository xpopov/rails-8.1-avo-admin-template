class Api::V1::HealthController < Api::V1::BaseController
  def show
    response.headers["Cache-Control"] = "no-store"
    render json: { status: "ok", service: "rails-8-avo", api_version: "v1" }
  end
end
