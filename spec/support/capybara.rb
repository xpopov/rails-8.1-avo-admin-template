require "capybara/rspec"
require "selenium-webdriver"

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.binary = ENV["CHROME_BIN"] if ENV["CHROME_BIN"].present?
  options.add_argument("--headless=new")
  options.add_argument("--window-size=1400,1000")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--no-sandbox") if ENV["CHROME_NO_SANDBOX"] == "1"

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.save_path = Rails.root.join("tmp/capybara")

RSpec.configure do |config|
  config.before(type: :system) { driven_by :headless_chrome }
end
