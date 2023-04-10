require 'cacheable'
require 'nexus_mods/core_extensions/cacheable/method_generator'
require 'nexus_mods/cacheable_with_expiry'

class NexusMods

  # Provide cacheable helpers for API methods that can be invalidated with an expiry time in seconds
  module CacheableApi

    # Callback when the module is included in another module/class
    #
    # Parameters::
    # * *base* (Class or Module): The class/module including this module
    def self.included(base)
      base.include CacheableWithExpiry
      base.extend CacheableApi::CacheableHelpers
    end

    # Some class helpers to make API calls easily cacheable
    module CacheableHelpers

      # Cache methods used for the NexusMods API with a given expiry time in seconds
      #
      # Parameters::
      # * *original_method_names* (Array<Symbol>): List of methods to which this cache apply
      # * *expiry_from_key* (Proc): Code giving the number of seconds of cache expiry from the key
      #   * Parameters::
      #     * *key* (String): The key for which we want the expiry time in seconds
      #   * Result::
      #     * Integer: Corresponding expiry time
      # * *on_cache_update* (Proc): Proc called when the cache has been updated
      # * *key_format* (Proc or nil): Optional proc giving the key format from the target of cacheable [default: nil].
      #   If nil then a default proc concatenating the target's class, method name and all arguments will be used.
      #   * Parameters::
      #     * *target* (Object): Object on which the method is cached
      #     * *method_name* (Symbol): Method being cached
      #     * *method_args* (Array<Object>): Method's arguments
      #     * *method_kwargs* (Hash<Symbol,Object>): Method's kwargs
      #   * Result::
      #     * String: The corresponding key to be used for caching
      def cacheable_api(*original_method_names, expiry_from_key:, on_cache_update:, key_format: nil)
        cacheable_with_expiry(
          *original_method_names,
          key_format: key_format || proc do |target, method_name, method_args, method_kwargs|
            (
              [
                target.class,
                method_name
              ] +
                method_args +
                method_kwargs.map { |key, value| "#{key}:#{value}" }
            ).join('/')
          end,
          expiry_from_key:,
          cache_options: {
            on_cache_update: proc do |_adapter, _key, _value, _options, _context|
              on_cache_update.call
            end
          }
        )
      end

    end

  end

end
