require "rails_helper"

RSpec.describe "API health", type: :request do
  it "returns public, non-cacheable versioned JSON without a session" do
    get "/api/v1/health", as: :json

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/json")
    expect(response.parsed_body).to eq("status" => "ok", "service" => "rails-8-avo", "api_version" => "v1")
    expect(response.headers["Cache-Control"]).to include("no-store")
  end
end
