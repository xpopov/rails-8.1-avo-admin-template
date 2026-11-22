require "rails_helper"

RSpec.describe "Sidekiq configuration" do
  it "uses Sidekiq outside tests and the isolated test adapter in specs" do
    expect(Rails.application.config.active_job.queue_adapter).to eq(:sidekiq)
    expect(ActiveJob::Base.queue_adapter).to be_a(ActiveJob::QueueAdapters::TestAdapter)
  end
end
