class AppInstance < String
  attr_reader :key, :local_url, :public_url

  def self.from_environment(env: ENV, rails_env: Rails.env)
    default_key = rails_env.to_s == "development" ? "localhost" : rails_env.to_s
    key = env["APP_STAGE"].presence || default_key
    scheme = %w[localhost test].include?(key) ? "http" : "https"
    url = env["APP_URL"].presence || "#{scheme}://#{env.fetch('APP_HOST', 'localhost:3000')}"
    new(key: key, local_url: env["APP_LOCAL_URL"].presence || url, public_url: env["APP_PUBLIC_URL"].presence || url)
  end

  def initialize(options)
    @key = options.fetch(:key).to_sym
    @local_url = options.fetch(:local_url).to_s.dup.freeze
    @public_url = options.fetch(:public_url).to_s.dup.freeze
    super(@key.to_s)
    freeze
  end

  def to_sym
    key
  end

  %i[localhost staging production test].each do |stage|
    define_method(:"#{stage}?") { key == stage }
  end
end
