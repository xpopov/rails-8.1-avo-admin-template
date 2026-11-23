require "rails_helper"
require "ostruct"
require "tempfile"

RSpec.describe SidekiqSerializer do
  it "recursively snapshots common Ruby and Rails objects into plain JSON values" do
    customer = build(:customer)
    time = Time.utc(2026, 11, 23, 12, 30)
    input = { status: :ok, values: [ false, nil, 42, BigDecimal("12.34"), time, Date.new(2026, 11, 23) ],
      object: OpenStruct.new(customer: customer), error: DetailedError.new("failed", details: { code: :busy }) }
    result = described_class.serialize(input)

    expect(JSON.parse(JSON.generate(result))).to eq(result)
    expect(result["values"]).to eq([ false, nil, 42, "12.34", time.iso8601(6), "2026-11-23" ])
    expect(result.dig("object", "customer", "name")).to eq(customer.name)
    expect(result["error"]).to include("class" => "DetailedError", "message" => "failed", "details" => { "code" => "busy" })
    expect(input[:status]).to eq(:ok)
  end

  it "snapshots unpermitted Rails request parameters" do
    params = ActionController::Parameters.new(token: "private", nested: { status: "pending" })
    expect(described_class.serialize(params)).to eq("token" => "private", "nested" => { "status" => "pending" })
    expect(params).not_to be_permitted
  end

  it "handles cycles, excessive nesting, nonfinite numbers, and unreadable objects" do
    cycle = {}; cycle[:self] = cycle
    broken = Class.new do
      def as_json(*) = raise(TypeError, "cannot serialize")
    end.new
    nested = 30.times.reduce(:leaf) { |value, _| [ value ] }
    result = described_class.serialize([ cycle, nested, Float::NAN, Float::INFINITY, broken ])

    expect { JSON.generate(result, allow_nan: false) }.not_to raise_error
    expect(result.first["self"]).to include("Circular")
    expect(result[1].flatten.first).to include("Max depth")
    expect(result[2..3]).to eq([ "NaN", "Infinity" ])
    expect(result.last).to include("Unserializable")
  end

  it "does not read files and repairs invalid string encodings" do
    Tempfile.create("log-details") do |file|
      file.write("private file contents")
      result = described_class.serialize(file: file, binary: "\xFF".b)
      expect(result["file"]).not_to include("private file contents")
      expect(result["binary"].encoding).to eq(Encoding::UTF_8)
      expect { JSON.generate(result) }.not_to raise_error
    end
  end

  it "copies shared objects without treating them as cycles" do
    shared = { key: "value" }
    result = described_class.serialize([ shared, shared ])
    result.first["key"].replace("changed")
    expect(shared[:key]).to eq("value")
    expect(result.last["key"]).to eq("value")
  end
end
