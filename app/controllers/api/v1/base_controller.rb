class Api::V1::BaseController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: { code: "not_found", message: "Record not found" } }, status: :not_found
  end
end
