require "rails_helper"

RSpec.describe "Avo CRM", type: :system do
  def login(user)
    visit "/login"
    fill_in "email", with: user.email
    fill_in "password", with: user.password
    click_button "Login"
    expect(page).to have_current_path("/resources/customers")
  end

  def save_record
    click_button "Save"
    expect(page).to have_no_button("Save")
  end

  it "lets staff create a customer, address, product, order and priced order line" do
    login(create(:user))
    expect(page).to have_no_link("Users", exact: true)
    visit "/resources/customers/new"
    fill_in "Name", with: "Acme Browser"
    fill_in "Email", with: "acme@example.com"
    save_record
    customer = Customer.find_by!(name: "Acme Browser")

    visit "/resources/addresses/new"
    select customer.name, from: "Customer"
    fill_in "Line1", with: "456 Example Avenue"
    fill_in "City", with: "Springfield"
    fill_in "Country code", with: "US"
    save_record
    expect(customer.addresses.sole.line1).to eq("456 Example Avenue")

    visit "/resources/products/new"
    fill_in "Name", with: "Browser Product"
    fill_in "Sku", with: "BROWSER-1"
    fill_in "Unit price", with: "24.95"
    save_record

    visit "/resources/sales_orders/new"
    select customer.name, from: "Customer"
    save_record
    order = customer.sales_orders.sole

    visit "/resources/sales_order_items/new"
    select order.display_name, from: "Sales order"
    select "Browser Product", from: "Product"
    fill_in "Quantity", with: "2"
    save_record
    expect(order.total).to eq(BigDecimal("49.90"))
    visit "/resources/sales_orders/#{order.id}"
    expect(page).to have_text("49.9")
  end

  it "lets an administrator create a user with a password through Avo" do
    login(create(:user, :admin))
    visit "/resources/users/new"
    fill_in "Name", with: "New Staff"
    fill_in "Email", with: "browserstaff@example.com"
    fill_in "Password", with: "a-secure-password"
    select "verified", from: "Status"
    save_record
    expect(User.find_by!(email: "browserstaff@example.com")).to be_verified
  end
end
