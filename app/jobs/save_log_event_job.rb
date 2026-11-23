class SaveLogEventJob < ApplicationJob
  queue_as :default

  def perform(type, message, tags = [], section = nil, exception_class = nil, details = {}, severity = nil)
    LogEntry.create!(
      type: type,
      message: message,
      tags: tags.is_a?(Array) ? tags.join(",") : tags&.to_s,
      section: section&.to_s,
      exception_class: exception_class,
      details: details,
      severity: severity
    )
  end
end
