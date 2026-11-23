require "rails_helper"

RSpec.describe SaveLogEventJob, type: :job do
  it "persists a serialized event and filters details for direct callers too" do
    perform_enqueued_jobs do
      described_class.perform_later("error", "Failure", [ "api" ], "requests", "IOError", { "token" => "private" }, 3)
    end
    expect(LogEntry.last).to have_attributes(type: "error", tags: "api", section: "requests", exception_class: "IOError", severity: 3)
    expect(LogEntry.last.details).to eq("token" => "[FILTERED]")
  end
end
