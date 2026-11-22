class Customer < ApplicationRecord
  has_many :addresses, dependent: :destroy
  has_many :sales_orders, dependent: :restrict_with_error

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
end
