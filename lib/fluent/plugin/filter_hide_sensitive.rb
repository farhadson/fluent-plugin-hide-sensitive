require 'fluent/plugin/filter'
require_relative 'version'

module Fluent::Plugin
  class HideSensitiveFilter < Filter
    Fluent::Plugin.register_filter('hide_sensitive', self)

    # === Plugin Configuration ===
    config_param :sensitive_keys, :array, default: []                # Keys to search for, e.g., ["token", "password"]
    config_param :search_path, :string, default: ''                  # Dot-separated path to nested object, e.g., "log.data.headers"
    config_param :output_key, :string, default: 'hidden_keys'        # Where to store extracted keys
    config_param :debug_mode, :bool, default: false                  # Whether to print debug info

    def configure(conf)
      super
      raise Fluent::ConfigError, "search_path must not be empty" if search_path.empty?

      # Split "log.data.headers" into ["log", "data", "headers"]
      @path_parts = @search_path.split('.')

      # Convert sensitive_keys into case-insensitive regex patterns
      @sensitive_patterns = @sensitive_keys.map do |k|
        Regexp.new(Regexp.escape(k), Regexp::IGNORECASE)
      end
    end

    def filter(tag, time, record)
      # Navigate to the specified nested object
      target = dig(record, @path_parts)

      # If the path doesn't point to a Hash, skip processing
      return record unless target.is_a?(Hash)

      hidden = {}

      # Extract sensitive keys into `hidden`, and track if any were removed
      modified = recursively_extract!(target, hidden, [])

      # Store hidden keys only if something was removed
      if modified
        log.debug "[hide_sensitive] tag=#{tag}, hidden_keys=#{hidden}" if @debug_mode
        record[@output_key] = hidden
      end

      record
    end

    private

    # Traverse a hash via a dot path like ["log", "data", "headers"]
    def dig(hash, path)
      path.reduce(hash) do |h, k|
        h.is_a?(Hash) ? h[k] : nil
      end
    end

    # Walk deeply through nested structure and filter sensitive keys
    def recursively_extract!(obj, hidden, path)
      return false unless obj.is_a?(Hash)
      modified = false

      obj.each_pair do |key, val|
        full_path = path + [key]  # Extend current path

        if val.is_a?(Hash)
          # Recurse into nested hashes
          modified |= recursively_extract!(val, hidden, full_path)
        elsif val.is_a?(Array)
          if array_contains_hash?(val)
            # Recurse into array of hashes
            val.each do |v|
              modified |= recursively_extract!(v, hidden, full_path) if v.is_a?(Hash)
            end
          else
            # Handle non-nested array values (e.g., ["token123"])
            modified |= remove_and_assign_if_sensitive(obj, hidden, key, val, full_path)
          end
        else
          # Handle leaf values directly
          modified |= remove_and_assign_if_sensitive(obj, hidden, key, val, full_path)
        end
      end

      modified
    end

    # Check and remove sensitive key if matched; assign to hidden
    def remove_and_assign_if_sensitive(obj, hidden, key, val, path)
      return false unless sensitive_key?(key)

      assign_nested(hidden, path, val)  # Store full path into hidden
      obj.delete(key)                   # Remove from original
      true
    end

    # Returns true if the array contains at least one Hash element
    def array_contains_hash?(arr)
      arr.any? { |e| e.is_a?(Hash) }
    end

    # Create a nested structure like: { "log" => { "data" => { "token" => "123" }}}
    def assign_nested(hash, path, value)
      *initial_keys, last_key = path
      current = hash
      initial_keys.each do |k|
        current[k] ||= {}       # Create nested hashes if they don't exist
        current = current[k]
      end
      current[last_key] = value
    end

    # Match key against the list of case-insensitive patterns
    def sensitive_key?(key)
      @sensitive_patterns.any? { |pattern| key.to_s =~ pattern }
    end
  end
end
