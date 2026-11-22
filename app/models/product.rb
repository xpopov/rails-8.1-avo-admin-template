class Product < ApplicationRecord
  has_many :sales_order_items, dependent: :restrict_with_error

  normalizes :sku, with: ->(value) { value.strip.upcase }
  validates :name, :sku, presence: true
  validates :sku, uniqueness: true
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }
end
