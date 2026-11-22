module RequestAuthentication
  def sign_in_user(user = create(:user))
    post "/login", params: { email: user.email, password: user.password || "correct-horse-battery-staple" }
    expect(response).to redirect_to("/")
    user
  end
end

RSpec.configure do |config|
  config.include RequestAuthentication, type: :request
end
