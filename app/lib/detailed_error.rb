class DetailedError < StandardError
  attr_reader :details

  def initialize(message, details: {})
    @details = details.dup.freeze
    super(message)
  end
end
