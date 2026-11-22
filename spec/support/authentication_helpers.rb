require "uri"

module AuthenticationHelpers
  def authentication_email_path(path)
    message = ActionMailer::Base.deliveries.last
    raise "No authentication email was delivered" unless message

    body = message.text_part&.decoded || message.body.decoded
    link = URI.extract(body, %w[http https]).map { |url| URI.parse(url) }.find { |url| url.path == path }
    raise "Authentication email has no #{path} link" unless link

    link.request_uri
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
  config.include AuthenticationHelpers, type: :system
end
