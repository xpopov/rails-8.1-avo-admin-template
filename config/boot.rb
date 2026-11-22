ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

# Public previews must not expose Vite's development filesystem proxy.
ENV["VITE_RUBY_MODE"] = "production" unless ENV["PUBLIC_PREVIEW_HOST"].to_s.empty?

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
