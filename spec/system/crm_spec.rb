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

  it "lets staff manage multiple addresses and order items from their parent tabs" do
    login(create(:user))
    expect(page).to have_no_link("Users", exact: true)
    expect(page).to have_no_link("Addresses", exact: true)
    expect(page).to have_no_link("Sales order items", exact: true)
    visit "/resources/customers/new"
    fill_in "Name", with: "Acme Browser"
    fill_in "Email", with: "acme@example.com"
    save_record
    customer = Customer.find_by!(name: "Acme Browser")

    [ "456 Example Avenue", "789 Shipping Street" ].each do |line1|
      visit "/resources/customers/#{customer.id}/edit?tab-group_customer=Details"
      expect(page).to have_field("Name", with: customer.name)
      find('[role="tab"]', text: "Addresses", exact_text: true).click
      within "turbo-frame#has_many_field_show_addresses" do
        find('a[href*="/resources/addresses/new"]').click
      end
      fill_in "Line1", with: line1
      fill_in "City", with: "Springfield"
      fill_in "Country code", with: "US"
      save_record
    end
    expect(customer.addresses.pluck(:line1)).to contain_exactly("456 Example Avenue", "789 Shipping Street")
    visit "/resources/customers/#{customer.id}/edit?tab-group_customer=Addresses"
    expect(page).to have_text("456 Example Avenue")
    expect(page).to have_text("789 Shipping Street")
    find('[role="tab"]', text: "Details", exact_text: true).click
    fill_in "Phone", with: "555-0100"
    click_button "Save"
    expect(page).to have_no_button("Save")
    expect(customer.reload.phone).to eq("555-0100")

    visit "/resources/products/new"
    fill_in "Name", with: "Browser Product"
    fill_in "Sku", with: "BROWSER-1"
    fill_in "Unit price", with: "24.95"
    save_record

    visit "/resources/sales_orders/new"
    select customer.name, from: "Customer"
    save_record
    order = customer.sales_orders.sole

    visit "/resources/sales_orders/#{order.id}/edit?tab-group_sales_order=Details"
    expect(page).to have_select("Customer", selected: customer.name)
    find('[role="tab"]', text: "Order items", exact_text: true).click
    within "turbo-frame#has_many_field_show_sales_order_items" do
      find('a[href*="/resources/sales_order_items/new"]').click
    end
    select "Browser Product", from: "Product"
    fill_in "Quantity", with: "2"
    save_record
    expect(order.sales_order_items.sole.quantity).to eq(2)
    expect(order.total).to eq(BigDecimal("49.90"))
    visit "/resources/sales_orders/#{order.id}?tab-group_sales_order=Details"
    expect(page).to have_text("49.9")
    find('[role="tab"]', text: "Order items", exact_text: true).click
    expect(page).to have_link("Browser Product", wait: 10)
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
