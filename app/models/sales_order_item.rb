class SalesOrderItem < ApplicationRecord
  belongs_to :sales_order
  belongs_to :product

  before_validation :capture_unit_price, on: :create

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }

  def display_name
    "#{product&.name} × #{quantity}"
  end

  def subtotal
    quantity * unit_price if quantity && unit_price
  end

  private

  def capture_unit_price
    self.unit_price = product&.unit_price if unit_price.nil?
  end
end
