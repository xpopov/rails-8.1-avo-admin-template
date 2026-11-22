require "rails_helper"

RSpec.describe "CRM", type: :request do
  %w[customers addresses products sales_orders sales_order_items].each do |resource|
    describe resource do
      include_examples "a CRM resource", "/resources/#{resource}"
    end
  end

  it "keeps addresses and order items out of the standalone navigation" do
    sign_in_user(create(:user, :admin))
    get "/resources/customers"
    page = Nokogiri::HTML(response.body)
    expect(page.at_css('a[href="/resources/addresses"]')).to be_nil
    expect(page.at_css('a[href="/resources/sales_order_items"]')).to be_nil
    expect(page.at_css('a[href="/resources/sales_orders"]')).to be_present
  end

  {
    customer: [ "customers", "customer", %w[Details Addresses Sales\ orders], "name" ],
    sales_order: [ "sales_orders", "sales_order", [ "Details", "Order items" ], "ordered_on" ]
  }.each do |factory, (resource, group_id, titles, attribute)|
    [ "", "/edit" ].each do |suffix|
      it "shows Details first and related tabs on #{resource} #{suffix.presence || 'show'}" do
        sign_in_user
        record = create(factory)
        get "/resources/#{resource}/#{record.id}#{suffix}"
        expect(response).to have_http_status(:ok)
        page = Nokogiri::HTML(response.body)
        group = page.at_css("[data-tabs-group-id-value='#{group_id}']")
        expect(group).to be_present
        expect(group["data-tabs-active-tab-value"]).to eq("Details")
        expect(group.css('[role="tablist"]').first.css('[role="tab"]').map(&:text).map(&:strip)).to eq(titles)
        if suffix == "/edit"
          expect(group.at_css("[data-tab-id='Details'] [name='#{factory}[#{attribute}]']")).to be_present
          expect(group.css("turbo-frame[src*='/#{resource}/#{record.id}/']")).not_to be_empty
        end
      end
    end

    it "only shows the Details tab when creating #{resource}" do
      sign_in_user
      get "/resources/#{resource}/new"
      expect(response).to have_http_status(:ok)
      tabs = Nokogiri::HTML(response.body).css('[role="tablist"]').first
      expect(tabs.css('[role="tab"]').map(&:text).map(&:strip)).to eq([ "Details" ])
    end
  end

  it "preserves customer and sales order index columns" do
    sign_in_user
    customer = create(:customer, name: "Index Customer", email: "index@example.com")
    order = create(:sales_order, customer: customer, status: :confirmed)
    create(:sales_order_item, sales_order: order, quantity: 2, unit_price: "12.34")

    get "/resources/customers"
    table = Nokogiri::HTML(response.body).at_css("table")
    expect(table.text).to include(customer.name, customer.email)

    get "/resources/sales_orders"
    table = Nokogiri::HTML(response.body).at_css("table")
    expect(table.text).to include(customer.name, "confirmed", "24.68")
  end

  it "lists only the current customer's multiple addresses" do
    sign_in_user
    customer = create(:customer)
    create(:address, customer: customer, line1: "Billing Street")
    create(:address, customer: customer, line1: "Shipping Street")
    create(:address, line1: "Other Customer Street")

    get "/resources/customers/#{customer.id}/edit"
    frame = Nokogiri::HTML(response.body).at_css("turbo-frame#has_many_field_show_addresses")
    get frame["src"]
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Billing Street", "Shipping Street")
    expect(response.body).not_to include("Other Customer Street")
  end

  it "lists only the current sales order's items" do
    sign_in_user
    order = create(:sales_order)
    product = create(:product, name: "Ordered Product")
    create(:sales_order_item, sales_order: order, product: product)
    create(:sales_order_item, product: create(:product, name: "Other Order Product"))

    get "/resources/sales_orders/#{order.id}/edit"
    frame = Nokogiri::HTML(response.body).at_css("turbo-frame#has_many_field_show_sales_order_items")
    get frame["src"]
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Ordered Product")
    expect(response.body).not_to include("Other Order Product")
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
