require "rails_helper"

RSpec.describe "Application loading" do
  it "eager loads all application classes" do
    expect { Rails.application.eager_load! }.not_to raise_error
  end
end
