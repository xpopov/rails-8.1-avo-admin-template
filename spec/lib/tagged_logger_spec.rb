require "rails_helper"
require "ostruct"

RSpec.describe TaggedLogger do
  it "persists synchronous events with the sales_portal calling convention" do
    entry = described_class.warning("Something happened", [ :billing, :retry ], :payments,
      details: { result: :pending }, severity: 2)
    expect(entry.reload).to have_attributes(type: "warning", tags: "billing,retry", section: "payments", severity: 2)
    expect(entry.details).to eq("result" => "pending")
    expect(described_class.tail(1, :payments)).to eq([ entry ])
  end

  it "snapshots and filters details before enqueueing and persists them through Active Job" do
    details = { object: OpenStruct.new(status: :pending), password: "private", false_value: false }
    expect do
      described_class.info("Queued", [ :async ], :jobs, async: true, details: details)
    end.to have_enqueued_job(SaveLogEventJob).on_queue("default")
    job = enqueued_jobs.last
    expect(JSON.generate(job.fetch("arguments"))).not_to include("private")
    details[:object].status = :changed
    perform_enqueued_jobs
    entry = LogEntry.last
    expect(entry.details).to include("object" => { "status" => "pending" }, "password" => "[FILTERED]", "false_value" => false)
    expect(entry).to have_attributes(type: "info", tags: "async", section: "jobs")
  end

  it "records exceptions with their class and backtrace without mutating options" do
    error = DetailedError.new("broken", details: { reason: :timeout })
    error.set_backtrace([ "example.rb:1" ])
    options = { details: { extra: :value } }.freeze
    entry = described_class.exception(error, "Import failed", [ :import ], :imports, options)
    expect(entry).to have_attributes(type: "exception", exception_class: "DetailedError")
    expect(entry.message).to include("Import failed", "broken", "example.rb:1")
    expect(entry.details.dig("exception", "details")).to eq("reason" => "timeout")
    expect(options).not_to have_key(:exception_class)
  end

  it "adds thread context without overriding explicit details" do
    Thread.current[:current_url] = "/current"
    Thread.current[:current_params] = { password: "private" }
    entry = described_class.debug("Request", [], nil, details: { "url" => "/explicit" })
    expect(entry.details).to include("url" => "/explicit", "params" => { "password" => "[FILTERED]" })
  ensure
    Thread.current[:current_url] = nil
    Thread.current[:current_params] = nil
  end
end
