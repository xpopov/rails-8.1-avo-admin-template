RSpec.configure do |config|
  config.around(:each, public_registration: true) do |example|
    previous = ENV["ALLOW_PUBLIC_REGISTRATION"]
    ENV["ALLOW_PUBLIC_REGISTRATION"] = "true"
    example.run
  ensure
    previous.nil? ? ENV.delete("ALLOW_PUBLIC_REGISTRATION") : ENV["ALLOW_PUBLIC_REGISTRATION"] = previous
  end
end
