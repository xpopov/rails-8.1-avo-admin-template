class HandleExceptionsService
  attr_reader :last_exception

  def initialize(message: "Operation failed", max_tries: 1, retry_on: [], wait: 0,
    details: {}, skip_logging: false, skip_raise: false, return_exception: false,
    on_exception: nil, before_retry: nil)
    raise ArgumentError, "max_tries must be a positive integer" unless max_tries.is_a?(Integer) && max_tries.positive?
    raise ArgumentError, "wait must be a finite nonnegative number" unless wait.is_a?(Numeric) && wait.finite? && wait >= 0
    unless retry_on.is_a?(Array) && retry_on.all? { |type| type.is_a?(Class) && type <= StandardError }
      raise ArgumentError, "retry_on must contain StandardError classes"
    end

    @message, @max_tries, @retry_on, @wait = message, max_tries, retry_on, wait
    @details = details.dup
    @skip_logging, @skip_raise, @return_exception = skip_logging, skip_raise, return_exception
    @on_exception, @before_retry = on_exception, before_retry
  end

  def perform
    attempts = 0
    @last_exception = nil

    begin
      attempts += 1
      yield
    rescue StandardError => error
      @last_exception = error
      @on_exception&.call(error, attempts)
      retrying = attempts < @max_tries && @retry_on.any? { |type| error.is_a?(type) }
      log_exception(error, attempts, retrying) unless @skip_logging

      if retrying
        @before_retry&.call(error, attempts)
        sleep @wait if @wait.positive?
        retry
      end

      suppress = @skip_raise.respond_to?(:call) ? @skip_raise.call(error) : @skip_raise
      raise unless suppress

      @return_exception ? { exception: error, details: @details.dup } : nil
    end
  end

  private

  def log_exception(error, attempts, retrying)
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    Rails.logger.warn(filter.filter({
      event: "operation_failed", operation: @message,
      exception_class: error.class.name, attempt: attempts, retrying: retrying, details: @details
    }).to_json)
  end
end
