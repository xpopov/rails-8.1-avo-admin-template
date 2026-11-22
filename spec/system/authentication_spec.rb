require "rails_helper"

RSpec.describe "Authentication", type: :system, public_registration: true do
  let(:password) { "correct-horse-battery-staple" }

  def sign_in(email:, password:, successful: true)
    visit "/login"
    fill_in "email", with: email
    fill_in "password", with: password
    click_button "Login"
    expect(page).to have_no_button("Login") if successful
  end

  def fill_registration(password: self.password)
    fill_in "email", with: "new@example.com"
    fill_in "password", with: password
    fill_in "password-confirm", with: password
  end

  it "lets an administrator sign in, open Avo, and sign out" do
    account = User.create!(email: "admin@example.com", status: :verified, password: password, admin: true)
    visit "/resources/users"
    expect(page).to have_current_path("/login")
    expect(page.evaluate_script("Boolean(window.Turbo && window.Stimulus)")).to be(true)
    expect(page.evaluate_script("getComputedStyle(document.body).color")).to eq("rgb(30, 41, 59)")

    fill_in "email", with: account.email
    fill_in "password", with: password
    click_button "Login"
    expect(page).to have_no_button("Login")
    visit "/resources/users"
    expect(page).to have_text(account.email)
    expect(page).to have_current_path("/resources/users")

    visit "/logout"
    click_button "Logout"
    expect(page).to have_current_path("/login")
    visit "/resources/users"
    expect(page).to have_current_path("/login")
  end

  it "rejects invalid credentials without granting access to Avo" do
    account = User.create!(email: "person@example.com", status: :verified, password: password)
    sign_in(email: account.email, password: "incorrect-password", successful: false)

    expect(page).to have_current_path("/login")
    expect(page).to have_text("There was an error logging in")
    visit "/resources/users"
    expect(page).to have_current_path("/login")
  end

  it "denies a regular user access to the background jobs dashboard" do
    account = User.create!(email: "person@example.com", status: :verified, password: password)
    sign_in(email: account.email, password: password)
    visit "/sidekiq"

    expect(page).to have_text("Forbidden")
    expect(page).to have_no_link("Queues")
  end

  it "shows registration validation errors without creating an account" do
    visit "/create-account"
    fill_registration(password: "short")
    click_button "Create Account"

    expect(page).to have_current_path("/create-account")
    expect(page).to have_text("There was an error creating your account")
    expect(User.find_by(email: "new@example.com")).to be_nil
  end

  it "registers and verifies an unprivileged account through email" do
    visit "/create-account"
    fill_registration
    perform_enqueued_jobs do
      click_button "Create Account"
      expect(page).to have_no_button("Create Account")
    end

    account = User.find_by!(email: "new@example.com")
    expect(account).to be_unverified
    expect(account).not_to be_admin

    visit authentication_email_path("/verify-account")
    click_button "Verify Account"
    expect(page).to have_no_button("Verify Account")
    expect(account.reload).to be_verified
    expect(account).not_to be_admin
  end

  it "changes a password through the account form" do
    account = User.create!(email: "admin@example.com", status: :verified, password: password, admin: true)
    new_password = "another-secure-password"
    sign_in(email: account.email, password: password)
    expect(page).to have_no_button("Login")

    visit "/change-password"
    fill_in "password", with: password
    fill_in "new-password", with: new_password
    fill_in "password-confirm", with: new_password
    click_button "Change Password"
    expect(page).to have_no_button("Change Password")

    visit "/logout"
    click_button "Logout"
    expect(page).to have_current_path("/login")
    sign_in(email: account.email, password: password, successful: false)
    expect(page).to have_text("There was an error logging in")
    sign_in(email: account.email, password: new_password)
    visit "/resources/users"
    expect(page).to have_text(account.email)
  end

  it "resets a forgotten password using the email link" do
    account = User.create!(email: "admin@example.com", status: :verified, password: password, admin: true)
    new_password = "another-secure-password"
    visit "/reset-password-request"
    fill_in "email", with: account.email
    perform_enqueued_jobs do
      click_button "Request Password Reset"
      expect(page).to have_no_button("Request Password Reset")
    end

    visit authentication_email_path("/reset-password")
    fill_in "password", with: new_password
    fill_in "password-confirm", with: new_password
    click_button "Reset Password"
    expect(page).to have_current_path("/login")

    sign_in(email: account.email, password: password, successful: false)
    expect(page).to have_text("There was an error logging in")
    sign_in(email: account.email, password: new_password)
    visit "/resources/users"
    expect(page).to have_text(account.email)
  end
end
