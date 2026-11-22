require "rails_helper"

RSpec.describe "CRM models", type: :model do
  it "requires customer name and validates optional email" do
    expect(build(:customer, name: nil)).not_to be_valid
    expect(build(:customer, email: "invalid")).not_to be_valid
    expect(build(:customer, email: nil)).to be_valid
  end

  it "requires a complete address and normalizes the country code" do
    address = build(:address, country_code: " us ")
    expect(address).to be_valid
    expect(address.country_code).to eq("US")
    expect(build(:address, city: nil)).not_to be_valid
    expect(build(:address, country_code: "USA")).not_to be_valid
  end

  it "normalizes unique product SKUs and rejects negative prices" do
    create(:product, sku: "abc")
    expect(build(:product, sku: " ABC ")).not_to be_valid
    expect(build(:product, unit_price: -1)).not_to be_valid
  end

  it "captures a price snapshot and totals line amounts using decimals" do
    order = create(:sales_order)
    product = create(:product, unit_price: "19.95")
    item = create(:sales_order_item, sales_order: order, product: product, quantity: 3)
    expect(item.unit_price).to eq(BigDecimal("19.95"))
    expect(item.subtotal).to eq(BigDecimal("59.85"))
    product.update!(unit_price: "99.99")
    item.update!(quantity: 2)
    expect(item.reload.unit_price).to eq(BigDecimal("19.95"))
    expect(order.total).to eq(BigDecimal("39.90"))
  end

  it "accepts explicitly negotiated line prices" do
    item = create(:sales_order_item, unit_price: "12.34", quantity: 2)
    expect(item.sales_order.total).to eq(BigDecimal("24.68"))
  end

  it "rejects invalid quantities, prices and order statuses" do
    expect(build(:sales_order_item, quantity: 0)).not_to be_valid
    expect(build(:sales_order_item, quantity: 1.5)).not_to be_valid
    expect(build(:sales_order_item, unit_price: -1)).not_to be_valid
    expect(build(:sales_order, status: "unknown")).not_to be_valid
  end

  it "restricts customer and product deletion while preserving order history" do
    item = create(:sales_order_item)
    expect(item.product.destroy).to be(false)
    expect(item.sales_order.customer.destroy).to be(false)
    expect { item.sales_order.destroy! }.to change(SalesOrderItem, :count).by(-1)
  end

  it "removes dependent addresses when deleting a customer without orders" do
    address = create(:address)
    expect { address.customer.destroy! }.to change(Address, :count).by(-1)
  end
end
