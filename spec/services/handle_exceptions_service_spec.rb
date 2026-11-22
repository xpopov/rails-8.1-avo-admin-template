require "rails_helper"
require "net/http"
require "stringio"

RSpec.describe HandleExceptionsService do
  it "returns the real operation result, including nil and false" do
    expect(described_class.new.perform { 123 }).to eq(123)
    expect(described_class.new.perform { nil }).to be_nil
    expect(described_class.new.perform { false }).to be(false)
  end

  it "does not retry programming errors by default" do
    attempts = 0
    expect do
      described_class.new(max_tries: 3).perform { attempts += 1; raise ArgumentError, "bad input" }
    end.to raise_error(ArgumentError, "bad input")
    expect(attempts).to eq(1)
  end

  it "retries only configured failures and stops at the attempt limit" do
    attempts = 0
    service = described_class.new(max_tries: 3, retry_on: [ IOError ], wait: 0.001)
    expect do
      service.perform { attempts += 1; raise IOError, "temporary" }
    end.to raise_error(IOError, "temporary")
    expect(attempts).to eq(3)
    expect(service.last_exception).to be_a(IOError)
  end

  it "invokes explicit hooks with the exception and attempt" do
    events = []
    attempts = 0
    service = described_class.new(max_tries: 2, retry_on: [ IOError ],
      on_exception: ->(error, attempt) { events << [ error.class, attempt ] },
      before_retry: ->(_error, attempt) { events << [ :retry, attempt ] })
    result = service.perform do
      attempts += 1
      raise IOError if attempts == 1
      :recovered
    end
    expect(result).to eq(:recovered)
    expect(events).to eq([ [ IOError, 1 ], [ :retry, 1 ] ])
    expect(service.perform { :next_operation }).to eq(:next_operation)
    expect(service.last_exception).to be_nil
  end

  it "supports a predicate for suppressing known failures" do
    error = DetailedError.new("expected", details: { code: :temporary })
    service = described_class.new(skip_raise: ->(failure) { failure.is_a?(DetailedError) }, return_exception: true)
    result = service.perform { raise error }
    expect(result[:exception]).to equal(error)
    expect(error.details).to eq(code: :temporary)
    expect { service.perform { raise ArgumentError } }.to raise_error(ArgumentError)
  end

  it "returns nil when suppression is requested without an exception result" do
    expect(described_class.new(skip_raise: true).perform { raise IOError }).to be_nil
  end

  it "never catches process shutdown or interrupts" do
    service = described_class.new(skip_raise: true)
    expect { service.perform { raise SystemExit, 1 } }.to raise_error(SystemExit)
    expect { service.perform { raise Interrupt } }.to raise_error(Interrupt)
  end

  it "rejects unbounded or invalid retry settings" do
    [ nil, 0, -1, 1.5 ].each do |value|
      expect { described_class.new(max_tries: value) }.to raise_error(ArgumentError)
    end
    [ -1, Float::INFINITY, Float::NAN ].each do |value|
      expect { described_class.new(wait: value) }.to raise_error(ArgumentError)
    end
    expect { described_class.new(retry_on: [ Exception ]) }.to raise_error(ArgumentError)
  end

  it "filters sensitive context and does not log raw exception messages" do
    original_logger = Rails.logger
    output = StringIO.new
    Rails.logger = ActiveSupport::Logger.new(output)
    described_class.new(details: { password: "private-password", safe: "value" }, skip_raise: true).perform do
      raise IOError, "private-exception-body"
    end
    expect(output.string).to include("[FILTERED]", "operation_failed", "value")
    expect(output.string).not_to include("private-password", "private-exception-body")
  ensure
    Rails.logger = original_logger
  end

  it "retries a real HTTP service and WebMock observes both unmocked requests" do
    with_local_http_service([ [ 503, "busy" ], [ 200, "healthy" ] ]) do |url|
      result = described_class.new(max_tries: 2, retry_on: [ Net::HTTPFatalError ]).perform do
        response = Net::HTTP.get_response(url)
        response.value
        response.body
      end
      expect(result).to eq("healthy")
      expect(a_request(:get, url.to_s)).to have_been_made.twice
    end
  end

  it "permits external calls by default without making a real external call" do
    expect(WebMock.net_connect_allowed?(URI("https://example.test"))).to be(true)
  end
end
