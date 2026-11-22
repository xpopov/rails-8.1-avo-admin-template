class SalesOrder < ApplicationRecord
  belongs_to :customer
  has_many :sales_order_items, dependent: :destroy

  enum :status, { draft: "draft", confirmed: "confirmed", completed: "completed", cancelled: "cancelled" }, validate: true
  attribute :ordered_on, :date, default: -> { Date.current }

  validates :ordered_on, presence: true

  def display_name
    "Order ##{id}"
  end

  def total
    sales_order_items.sum("quantity * unit_price")
  end
end
