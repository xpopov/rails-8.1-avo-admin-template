FactoryBot.define do
  factory :customer do
    name { "Example Customer" }
    sequence(:email) { |n| "customer#{n}@example.com" }
  end

  factory :address do
    customer
    line1 { "123 Example Street" }
    city { "Springfield" }
    country_code { "US" }
  end

  factory :product do
    name { "Example Product" }
    sequence(:sku) { |n| "SKU-#{n}" }
    unit_price { "19.95" }
  end

  factory :sales_order do
    customer
  end

  factory :sales_order_item do
    sales_order
    product
    quantity { 1 }
  end
end
