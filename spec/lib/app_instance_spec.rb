require "rails_helper"

RSpec.describe AppInstance do
  it "initializes the global and Rails configuration with the same instance" do
    expect($app).to be_a(described_class)
    expect($app).to equal(Rails.configuration.x.app_instance)
    expect($app.test?).to be(true)
    expect($app.to_sym).to eq(:test)
    expect($app.to_s).to eq("test")
  end

  it "defaults appropriately in each Rails environment" do
    { "development" => :localhost, "test" => :test, "production" => :production, "staging" => :staging }.each do |environment, key|
      app = described_class.from_environment(env: {}, rails_env: environment)
      expect(app.key).to eq(key)
      expect(app.public_url).to be_present
      expect(app.local_url).to be_present
    end
  end

  it "supports explicit stages and distinct public and internal URLs" do
    app = described_class.from_environment(env: { "APP_STAGE" => "staging", "APP_HOST" => "app.example.test",
      "APP_LOCAL_URL" => "http://web:3000", "APP_PUBLIC_URL" => "https://staging.example.test" }, rails_env: "production")
    expect(app.staging?).to be(true)
    expect(app.production?).to be(false)
    expect(app.local_url).to eq("http://web:3000")
    expect(app.public_url).to eq("https://staging.example.test")
    expect(app).to be_frozen
  end

  it "uses APP_URL as a shared URL and APP_HOST as its default" do
    expect(described_class.from_environment(env: { "APP_URL" => "https://app.example.test" }, rails_env: "production").local_url).to eq("https://app.example.test")
    expect(described_class.from_environment(env: { "APP_HOST" => "localhost:4000" }, rails_env: "development").public_url).to eq("http://localhost:4000")
  end
end
