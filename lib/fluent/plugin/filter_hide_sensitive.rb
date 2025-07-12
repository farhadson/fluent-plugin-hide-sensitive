require 'fluent/plugin/filter'
require_relative 'version'

module Fluent::Plugin
  class HideSensitiveFilter < Filter
    Fluent::Plugin.register_filter('hide_sensitive', self)

    config_param :sensitive_keys, :array, default: []
    config_param :search_path, :string, default: ''
    config_param :output_key, :string, default: 'hidden_keys'

    def configure(conf)
      super
      @path_parts = @search_path.split('.')
      @sensitive_patterns = @sensitive_keys.map { |k| Regexp.new(Regexp.escape(k), Regexp::IGNORECASE) }
    end

    def filter(tag, time, record)
      target = dig(record, @path_parts)
      return record unless target.is_a?(Hash)

      hidden = {}
      recursively_extract!(target, hidden, [])

      record[@output_key] = hidden unless hidden_empty?(hidden)
      record
    end

    private

    def dig(hash, path)
      path.reduce(hash) do |h, k|
        h.is_a?(Hash) ? h[k] : nil
      end
    end

    def recursively_extract!(obj, hidden, path)
      return unless obj.is_a?(Hash)

      obj.keys.each do |key|
        val = obj[key]
        full_path = path + [key]

        if sensitive_key?(key)
          assign_nested(hidden, full_path, val)
          obj.delete(key)
        elsif val.is_a?(Hash)
          recursively_extract!(val, hidden, full_path)
        elsif val.is_a?(Array)
          val.each { |v| recursively_extract!(v, hidden, full_path) if v.is_a?(Hash) }
        end
      end
    end

    def assign_nested(hash, path, value)
      *initial_keys, last_key = path
      current = hash
      initial_keys.each do |k|
        current[k] ||= {}
        current = current[k]
      end
      current[last_key] = value
    end

    def hidden_empty?(obj)
      case obj
      when Hash
        obj.all? { |_, v| hidden_empty?(v) }
      else
        false
      end
    end

    def sensitive_key?(key)
      @sensitive_patterns.any? { |pattern| key.to_s =~ pattern }
    end
  end
end
