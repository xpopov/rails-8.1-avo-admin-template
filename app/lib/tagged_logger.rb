module TaggedLogger
  class << self
    %i[debug info warning error].each do |level|
      define_method(level) do |message, tags = [], section = nil, options = {}|
        _log(level, message.to_s, tags, section, options)
      end
    end

    def exception(error, message = "", tags = [], section = nil, options = {})
      details = LogEntry.filtered_details(options[:details])
      details["exception"] = SidekiqSerializer.serialize(error)
      text = [ message, error.message, *error.backtrace ].reject(&:blank?).join("\n\n")
      _log(:exception, text, tags, section,
        options.merge(exception_class: options[:exception_class].presence || error.class.name, details: details))
    end

    def _log(type, message, tags = [], section = nil, options = {})
      details = LogEntry.filtered_details(options[:details])
      %i[url user ip params].each do |key|
        value = Thread.current[:"current_#{key}"]
        details[key.to_s] = SidekiqSerializer.serialize(value) if !details.key?(key.to_s) && !value.nil?
      end
      details = LogEntry.filtered_details(details)
      arguments = SidekiqSerializer.serialize([ type, message, tags, section, options[:exception_class], details, options[:severity] ])

      if options.fetch(:async, false)
        SaveLogEventJob.perform_later(*arguments)
      else
        SaveLogEventJob.perform_now(*arguments)
      end
    end

    def tail(limit = nil, section = nil)
      entries = LogEntry.sorted.limit(limit)
      section.present? ? entries.where(section: section.to_s) : entries
    end
  end
end
