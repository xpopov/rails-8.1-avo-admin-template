require "bigdecimal"
require "date"
require "time"

class SidekiqSerializer
  MAX_DEPTH = 20

  def self.serialize(value)
    new.serialize(value)
  end

  def serialize(value, ancestors = {}, depth = 0)
    case value
    when NilClass, TrueClass, FalseClass, Integer
      value
    when String, Symbol
      text(value.to_s)
    when Float
      value.finite? ? value : value.to_s
    when BigDecimal
      value.to_s("F")
    when Time, DateTime
      value.iso8601(6)
    when Date
      value.iso8601
    else
      return "[Max depth reached]" if depth >= MAX_DEPTH
      return "[Circular #{value.class}]" if ancestors.key?(value.object_id)

      ancestors[value.object_id] = true
      begin
        convert(value, ancestors, depth)
      ensure
        ancestors.delete(value.object_id)
      end
    end
  rescue StandardError
    "[Unserializable #{value.class}]"
  end

  private

  def convert(value, ancestors, depth)
    case value
    when Hash
      value.each_with_object({}) do |(key, item), result|
        result[text(key.to_s)] = serialize(item, ancestors, depth + 1)
      end
    when Array
      value.map { |item| serialize(item, ancestors, depth + 1) }
    when Exception
      attributes = { class: value.class.name, message: value.message, backtrace: value.backtrace }
      attributes[:details] = value.details if value.respond_to?(:details)
      serialize(attributes, ancestors, depth + 1)
    else
      return "#<#{value.class}>" if value.respond_to?(:read) && value.respond_to?(:close)

      converted = if value.respond_to?(:to_unsafe_h)
        value.to_unsafe_h
      elsif value.respond_to?(:to_h)
        value.to_h
      elsif value.respond_to?(:as_json)
        value.as_json
      else
        value.to_s
      end
      serialize(converted, ancestors, depth + 1)
    end
  end

  def text(value)
    value.encode(Encoding::UTF_8, invalid: :replace, undef: :replace).delete("\u0000")
  end
end
