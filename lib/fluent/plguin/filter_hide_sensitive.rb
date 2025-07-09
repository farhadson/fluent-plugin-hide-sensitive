require 'fluent/plugin/filter'

module Fluent::Plugin
  class HideSensitiveFilter < Filter
    Fluent::Plugin.register_filter('hide_sensitive', self)

    config_param :sensitive_keys, :array, default: []
    config_param :search_path, :string, default: ''
    config_param :output_key, :string, default: 'hidden_keys'

    def configure(conf)
      super
      @path_parts = @search_path.split('.')
    end

    def filter(tag, time, record)
      target = dig(record, @path_parts)

      return record unless target.is_a?(Hash)

      hidden = {}

      @sensitive_keys.each do |key|
        if target.key?(key)
          hidden[key] = target.delete(key)
        end
      end

      # Set hidden_keys at root level
      record[@output_key] = hidden unless hidden.empty?

      record
    end

    private

    def dig(hash, path)
      path.reduce(hash) do |h, k|
        h.is_a?(Hash) ? h[k] : nil
      end
    end
  end
end
