class LogEntry < ApplicationRecord
  self.inheritance_column = :_type_disabled

  enum :type, { debug: 1, info: 2, warning: 3, error: 4, exception: 5 }

  validates :message, :type, presence: true
  before_validation :normalize_details

  scope :sorted, -> { order(id: :desc) }

  def self.filtered_details(details)
    snapshot = SidekiqSerializer.serialize(details.nil? ? {} : details)
    snapshot = { "value" => snapshot } unless snapshot.is_a?(Hash)
    ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters).filter(snapshot)
  end

  private

  def normalize_details
    self.details = self.class.filtered_details(details)
  end
end
