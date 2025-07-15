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
      # Split dotted path like "log.data.headers" into ["log", "data", "headers"]
      @path_parts = @search_path.split('.')

      # Compile sensitive key matchers like /token/i, /pass/i
      @sensitive_patterns = @sensitive_keys.map do |k|
        Regexp.new(Regexp.escape(k), Regexp::IGNORECASE)
      end
    end

    def filter(tag, time, record)
      # Navigate to the target nested object
      target = dig(record, @path_parts)

      # If that path doesn't lead to a hash, skip
      return record unless target.is_a?(Hash)

      hidden = {}

      # Recursively walk through nested hashes
      recursively_extract!(target, hidden, [])

      # If we found any hidden keys, store them
      record[@output_key] = hidden unless hidden_empty?(hidden)
      record
    end

    private

    # Follow the path like record["log"]["data"]["headers"]
    def dig(hash, path)
      path.reduce(hash) do |h, k|
        h.is_a?(Hash) ? h[k] : nil
      end
    end

    # Walk deeply through nested structures
    def recursively_extract!(obj, hidden, path)
      return unless obj.is_a?(Hash)

      obj.keys.each do |key|
        val = obj[key]
        full_path = path + [key]  # ✅ Correct way to extend path for this key

        if sensitive_key?(key)
          assign_nested(hidden, full_path, val)  # Store full path into hidden
          obj.delete(key)                        # Remove from original
        elsif val.is_a?(Hash)
          recursively_extract!(val, hidden, full_path)
        elsif val.is_a?(Array)
          val.each { |v| recursively_extract!(v, hidden, full_path) if v.is_a?(Hash) }
        end
      end
    end

    # Build nested hash structure in hidden, based on path
    def assign_nested(hash, path, value)
      *initial_keys, last_key = path
      current = hash
      initial_keys.each do |k|
        current[k] ||= {}       # Create nested hashes if missing
        current = current[k]
      end
      current[last_key] = value
    end

    # Check if all branches are empty (used to decide if we skip storing hidden_keys)
    def hidden_empty?(obj)
      case obj
      when Hash
        obj.all? { |_, v| hidden_empty?(v) }
      else
        false
      end
    end

    # Case-insensitive matching against key
    def sensitive_key?(key)
      @sensitive_patterns.any? { |pattern| key.to_s =~ pattern }
    end
  end
end
