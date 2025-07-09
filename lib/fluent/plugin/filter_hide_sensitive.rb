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
      recursively_extract!(target, hidden)

      record[@output_key] = hidden unless hidden.empty?
      record
    end

    private

    def dig(hash, path)
      path.reduce(hash) do |h, k|
        h.is_a?(Hash) ? h[k] : nil
      end
    end

    def recursively_extract!(obj, hidden)
      return unless obj.is_a?(Hash)

      obj.keys.each do |key|
        val = obj[key]
        if sensitive_key?(key)
          hidden[key] = obj.delete(key)
        elsif val.is_a?(Hash)
          recursively_extract!(val, hidden)
        elsif val.is_a?(Array)
          val.each { |v| recursively_extract!(v, hidden) if v.is_a?(Hash) }
        end
      end
    end

    def sensitive_key?(key)
      @sensitive_patterns.any? { |pattern| key.to_s =~ pattern }
    end
  end
end
