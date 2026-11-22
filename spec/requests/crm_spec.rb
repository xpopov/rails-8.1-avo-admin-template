require "rails_helper"

RSpec.describe "CRM", type: :request do
  %w[customers addresses products sales_orders sales_order_items].each do |resource|
    describe resource do
      include_examples "a CRM resource", "/resources/#{resource}"
    end
  end

  it "allows a user to create, edit, and delete a customer" do
    sign_in_user
    expect do
      post "/resources/customers", params: { customer: { name: "Acme", email: "hello@example.com" } }
    end.to change(Customer, :count).by(1)
    customer = Customer.find_by!(name: "Acme")
    expect(response).to have_http_status(:redirect)

    patch "/resources/customers/#{customer.id}", params: { customer: { name: "Acme Updated" } }
    expect(customer.reload.name).to eq("Acme Updated")
    delete "/resources/customers/#{customer.id}"
    expect(Customer.exists?(customer.id)).to be(false)
  end

  it "does not allow unverified users into the CRM" do
    user = create(:user, :unverified)
    post "/login", params: { email: user.email, password: user.password }
    get "/resources/customers"
    expect(response).not_to have_http_status(:ok)
  end

  it "blocks user management mutations and search for non-admins" do
    staff = sign_in_user
    target = create(:user)
    post "/resources/users", params: { user: attributes_for(:user, :admin) }
    expect(response).to have_http_status(:forbidden)
    patch "/resources/users/#{staff.id}", params: { user: { admin: true } }
    expect(response).to have_http_status(:forbidden)
    expect(staff.reload).not_to be_admin
    delete "/resources/users/#{target.id}"
    expect(response).to have_http_status(:forbidden)
    expect(target.reload).to be_persisted
    get "/avo_api/users/search", params: { q: target.email }
    expect(response).to have_http_status(:forbidden)
  end

  it "lets an admin manage a user's password without exposing its hash" do
    sign_in_user(create(:user, :admin))
    post "/resources/users", params: { user: { email: "newstaff@example.com", password: "new-secure-password", status: "verified", admin: false } }
    user = User.find_by!(email: "newstaff@example.com")
    expect(user).to be_verified
    get "/resources/users/#{user.id}"
    expect(response.body).not_to include(user.password_hash)

    patch "/resources/users/#{user.id}", params: { user: { name: "Updated", password: "" } }
    expect(user.reload.name).to eq("Updated")
    post "/logout"
    post "/login", params: { email: user.email, password: "new-secure-password" }
    expect(response).to redirect_to("/")
  end

  it "revokes CRM access when the signed-in user is closed" do
    user = sign_in_user
    user.update!(status: :closed)
    get "/resources/customers"
    expect(response).not_to have_http_status(:ok)
  end

  it "revokes CRM access when the signed-in user is deleted" do
    user = sign_in_user
    user.destroy!
    get "/resources/customers"
    expect(response).not_to have_http_status(:ok)
  end
  it "rechecks administrator privileges on every request" do
    user = sign_in_user(create(:user, :admin))
    user.update!(admin: false)
    get "/resources/users"
    expect(response).to have_http_status(:forbidden)
    get "/resources/customers"
    expect(response).to have_http_status(:ok)
  end
end
