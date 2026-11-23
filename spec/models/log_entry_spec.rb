require "rails_helper"

RSpec.describe LogEntry, type: :model do
  it "uses type as a severity enum rather than STI" do
    described_class.types.each_key do |type|
      entry = described_class.create!(type: type, message: "event")
      expect(entry.reload.type).to eq(type)
    end
    expect(described_class.new).not_to be_valid
  end

  it "filters nested sensitive details without modifying the caller's data" do
    details = { password: "private", nested: [ { api_token: "secret", safe: false } ] }
    entry = described_class.create!(type: :info, message: "event", details: details)
    expect(entry.reload.details).to eq("password" => "[FILTERED]", "nested" => [ { "api_token" => "[FILTERED]", "safe" => false } ])
    expect(details[:password]).to eq("private")
    entry.update!(details: { password: "changed" })
    expect(entry.reload.details).to eq("password" => "[FILTERED]")
  end
end
