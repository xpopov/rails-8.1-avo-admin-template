class Address < ApplicationRecord
  belongs_to :customer

  normalizes :country_code, with: ->(value) { value.strip.upcase }
  validates :line1, :city, :country_code, presence: true
  validates :country_code, format: { with: /\A[A-Z]{2}\z/ }

  def display_name
    [ label, line1, city, country_code ].compact_blank.join(", ")
  end
end
