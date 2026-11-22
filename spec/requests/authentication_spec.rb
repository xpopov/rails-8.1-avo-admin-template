require "rails_helper"

RSpec.describe "Authentication", type: :request do
  let(:password) { "correct-horse-battery-staple" }
  let(:new_password) { "another-secure-password" }
  let(:account) { Account.create!(email: "person@example.com", status: :verified, password: password) }

  def registration_params
    {
      email: "new@example.com", password: password, "password-confirm": password
    }
  end

  def follow_authentication_link(path)
    get path
    follow_redirect! while response.redirect?
  end

  it "registers and verifies an account using the delivered email token" do
    perform_enqueued_jobs do
      post "/create-account", params: registration_params.merge(admin: true, status: "verified")
    end

    registered = Account.find_by!(email: "new@example.com")
    expect(registered).to be_unverified
    expect(registered).not_to be_admin
    expect(ActionMailer::Base.deliveries.last.to).to eq([ registered.email ])

    follow_authentication_link(authentication_email_path("/verify-account"))
    expect(response).to have_http_status(:ok)
    post "/verify-account"

    expect(response).to have_http_status(:redirect)
    expect(registered.reload).to be_verified
    expect(registered).not_to be_admin
  end

  {
    "invalid email" => { email: "not-an-email" },
    "short password" => { password: "short", "password-confirm": "short" },
    "mismatched password confirmation" => { "password-confirm": "different-password" }
  }.each do |description, overrides|
    it "rejects registration with #{description}" do
      expect do
        post "/create-account", params: registration_params.merge(overrides)
      end.not_to change(Account, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(enqueued_jobs).to be_empty
    end
  end

  it "rejects an existing email regardless of case" do
    email = account.email.upcase

    expect do
      post "/create-account", params: registration_params.merge(email: email)
    end.not_to change(Account, :count)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "does not verify an account with a tampered email token" do
    perform_enqueued_jobs { post "/create-account", params: registration_params }
    path = authentication_email_path("/verify-account")
    key = Rack::Utils.parse_query(URI.parse(path).query).fetch("key")

    get "/verify-account", params: { key: "#{key}tampered" }
    post "/verify-account", params: { key: "#{key}tampered" }

    expect(Account.find_by!(email: "new@example.com")).to be_unverified
  end

  it "resets a password using the delivered email and invalidates the old password" do
    perform_enqueued_jobs { post "/reset-password-request", params: { email: account.email } }
    path = authentication_email_path("/reset-password")

    expect(ActionMailer::Base.deliveries.last.to).to eq([ account.email ])
    follow_authentication_link(path)
    expect(response).to have_http_status(:ok)
    post "/reset-password", params: { password: new_password, "password-confirm": new_password }
    expect(response).to redirect_to("/login")

    post "/login", params: { email: account.email, password: password }
    expect(response).to have_http_status(:unauthorized)
    post "/login", params: { email: account.email, password: new_password }
    expect(response).to redirect_to("/")

    post "/logout"
    follow_authentication_link(path)
    post "/reset-password", params: { password: password, "password-confirm": password }
    post "/login", params: { email: account.email, password: password }
    expect(response).to have_http_status(:unauthorized)
  end

  it "does not reset a password with an expired token" do
    perform_enqueued_jobs { post "/reset-password-request", params: { email: account.email } }
    path = authentication_email_path("/reset-password")
    Account.connection.execute("UPDATE account_password_reset_keys SET deadline = CURRENT_TIMESTAMP - INTERVAL '1 day' WHERE id = #{account.id}")

    follow_authentication_link(path)
    post "/reset-password", params: { password: new_password, "password-confirm": new_password }
    post "/login", params: { email: account.email, password: new_password }
    expect(response).to have_http_status(:unauthorized)
    post "/login", params: { email: account.email, password: password }
    expect(response).to redirect_to("/")
  end

  it "does not send password reset mail for an unknown account" do
    expect do
      perform_enqueued_jobs do
        post "/reset-password-request", params: { email: "unknown@example.com" }
      end
    end.not_to change(Account, :count)

    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "requires the current password before changing it" do
    post "/login", params: { email: account.email, password: password }
    post "/change-password", params: {
      password: "incorrect", "new-password": new_password, "password-confirm": new_password
    }
    expect(response).to have_http_status(:unauthorized)

    post "/change-password", params: {
      password: password, "new-password": new_password, "password-confirm": new_password
    }
    expect(response).to have_http_status(:redirect)
    post "/logout"
    post "/login", params: { email: account.email, password: password }
    expect(response).to have_http_status(:unauthorized)
    post "/login", params: { email: account.email, password: new_password }
    expect(response).to redirect_to("/")
  end

  it "does not authenticate closed accounts" do
    account.update!(status: :closed)
    post "/login", params: { email: account.email, password: password }

    expect(response).not_to have_http_status(:redirect)
    get "/resources/accounts"
    expect(response).to redirect_to("/login")
  end

  it "requires authentication to change a password" do
    post "/change-password", params: {
      password: password, "new-password": new_password, "password-confirm": new_password
    }

    expect(response).to redirect_to("/login")
  end
end
