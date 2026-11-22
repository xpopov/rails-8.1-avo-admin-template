require "rails_helper"

RSpec.describe "Application access", type: :request do
  let(:password) { "correct-horse-battery-staple" }

  def sign_in(admin: false)
    account = Account.create!(email: "person@example.com", status: :verified, password: password, admin: admin)
    post "/login", params: { email: account.email, password: password }
    expect(response).to have_http_status(:redirect)
    account
  end

  it "renders a login field that accepts usernames" do
    get "/login"
    expect(response).to have_http_status(:ok)
    input = Nokogiri::HTML(response.body).at_css('input[name="email"]')
    expect(input["type"]).to eq("text")
  end

  it "serves Avo account resources at the root mount" do
    sign_in(admin: true)
    get "/resources/accounts"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("person@example.com")
  end

  it "signs the seeded admin into Avo with admin/admin" do
    load Rails.root.join("db/seeds.rb")
    account = Account.find_by!(email: "admin")
    expect(account).to be_verified
    expect(account).to be_admin
    expect(account.password_hash).not_to eq("admin")

    post "/login", params: { email: "admin", password: "admin" }
    expect(response).to redirect_to("/")
    follow_redirect!
    follow_redirect! if response.redirect?
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("/resources/accounts")
  end

  it "does not reset an existing admin password when reseeding" do
    load Rails.root.join("db/seeds.rb")
    account = Account.find_by!(email: "admin")
    account.update!(password: password)
    password_hash = account.password_hash

    expect { load Rails.root.join("db/seeds.rb") }.not_to change(Account, :count)
    expect(account.reload.password_hash).to eq(password_hash)
    post "/login", params: { email: "admin", password: password }
    expect(response).to redirect_to("/")
  end

  it "does not reopen an existing closed admin when reseeding" do
    load Rails.root.join("db/seeds.rb")
    account = Account.find_by!(email: "admin")
    account.update!(status: :closed)
    load Rails.root.join("db/seeds.rb")
    expect(account.reload).to be_closed
  end

  it "does not allow public registration of the admin username" do
    load Rails.root.join("db/seeds.rb")
    post "/create-account", params: {
      email: "admin", "email-confirm": "admin",
      password: password, "password-confirm": password
    }
    expect(response).to have_http_status(:unprocessable_content)
    expect(Account.where(email: "admin").count).to eq(1)
  end

  it "keeps the normal minimum password length for registration" do
    post "/create-account", params: {
      email: "new@example.com", "email-confirm": "new@example.com",
      password: "admin", "password-confirm": "admin"
    }
    expect(response).to have_http_status(:unprocessable_content)
    expect(Account.find_by(email: "new@example.com")).to be_nil
  end

  it "reports application health" do
    get "/up"
    expect(response).to have_http_status(:ok)
  end

  [ "/", "/resources/accounts", "/sidekiq" ].each do |path|
    it "redirects guests away from #{path}" do
      get path
      expect(response).to redirect_to("/login")
    end

    it "denies non-admin accounts access to #{path}" do
      sign_in
      get path
      expect(response).to have_http_status(:forbidden)
    end

    it "allows admin accounts access to #{path}" do
      sign_in(admin: true)
      get path
      follow_redirect! while response.redirect?
      expect(response).to have_http_status(:ok)
    end
  end

  it "logs an account out" do
    sign_in
    post "/logout"
    get "/"
    expect(response).to redirect_to("/login")
  end

  it "registers an unprivileged account and queues verification email" do
    expect do
      post "/create-account", params: {
        email: "new@example.com", "email-confirm": "new@example.com",
        password: password, "password-confirm": password, admin: true
      }
    end.to have_enqueued_job(ActionMailer::MailDeliveryJob)
    expect(response).to have_http_status(:redirect)
    account = Account.find_by!(email: "new@example.com")
    expect(account).not_to be_admin
    expect(account).to be_unverified
  end

  it "rejects an incorrect password" do
    Account.create!(email: "person@example.com", status: :verified, password: password)
    post "/login", params: { email: "person@example.com", password: "incorrect" }
    expect(response).to have_http_status(:unauthorized)
    get "/"
    expect(response).to redirect_to("/login")
  end
end
