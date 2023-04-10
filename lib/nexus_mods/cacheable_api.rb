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
      def cacheable_api(*original_method_names, expiry_from_key:)
        cacheable_with_expiry(
          *original_method_names,
          key_format: lambda do |target, method_name, method_args, method_kwargs|
            (
              [
                target.class,
                method_name
              ] +
                method_args +
                method_kwargs.map { |key, value| "#{key}:#{value}" }
            ).join('/')
          end,
          expiry_from_key:
        )
      end

    end

  end

end
