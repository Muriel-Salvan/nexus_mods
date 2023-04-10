require 'time'
require 'nexus_mods/core_extensions/cacheable/cache_adapters/persistent_json_adapter'

class NexusMods

  # Add cacheable properties that can be expired using time in seconds
  module CacheableWithExpiry

    # Callback when the module is included in another module/class
    #
    # Parameters::
    # * *base* (Class or Module): The class/module including this module
    def self.included(base)
      base.include Cacheable
      base.extend CacheableWithExpiry::CacheableHelpers
    end

    # Some class helpers to make cacheable calls easy with expiry proc
    module CacheableHelpers

      # Wrap Cacheable's cacheable method to add the expiry_rules kwarg and use to invalidate the cache of a PersistentJsonAdapter based on the key format.
      #
      # Parameters::
      # * *original_method_names* (Array<Symbol>): List of methods to which this cache apply
      # * *opts* (Hash<Symbol,Object>): kwargs that will be transferred to the cacheable method, with the following ones interpreted:
      #   * *expiry_from_key* (Proc): Code giving the number of seconds of cache expiry from the key
      #     * Parameters::
      #       * *key* (String): The key for which we want the expiry time in seconds
      #     * Result::
      #       * Integer: Corresponding expiry time
      def cacheable_with_expiry(*original_method_names, **opts)
        expiry_cache = {}
        cacheable(
          *original_method_names,
          **opts.merge(
            {
              cache_options: {
                expiry_from_key: opts[:expiry_from_key],
                invalidate_if: proc do |key, options, context|
                  next true unless context['invalidate_time']

                  # Find if we know already the expiry for this key
                  expiry_cache[key] = options[:expiry_from_key].call(key) unless expiry_cache.key?(key)
                  expiry_cache[key].nil? || (Time.now.utc - Time.parse(context['invalidate_time']).utc > expiry_cache[key])
                end,
                update_context_after_fetch: proc do |_key, _value, _options, context|
                  context['invalidate_time'] = Time.now.utc.strftime('%FT%TUTC')
                end
              }
            }
          )
        )
        @_cacheable_expiry_caches = [] unless defined?(@_cacheable_expiry_caches)
        @_cacheable_expiry_caches << expiry_cache
      end

      # Clear expiry times caches
      def clear_cacheable_expiry_caches
        return unless defined?(@_cacheable_expiry_caches)

        @_cacheable_expiry_caches.each do |expiry_cache|
          expiry_cache.replace({})
        end
      end

    end

  end

end
