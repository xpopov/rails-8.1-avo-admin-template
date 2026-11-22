class User < ApplicationRecord
  include Rodauth::Rails.model

  enum :status, { unverified: 1, verified: 2, closed: 3 }

  scope :administrators, -> { where(admin: true) }
  scope :active, -> { verified }

  validates :email, presence: true
  validates :password_hash, presence: true, unless: :closed?
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, unless: -> { email == "admin" }
  validates :email, uniqueness: { case_sensitive: false, conditions: -> { where(status: [ 1, 2 ]) } }, unless: :closed?
  validates :password, length: { minimum: 8, maximum: 72 }, allow_nil: true

  def password=(value)
    super if value.present?
  end
end
