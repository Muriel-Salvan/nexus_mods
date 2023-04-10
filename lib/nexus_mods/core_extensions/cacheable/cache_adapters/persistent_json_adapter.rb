require 'cacheable'
require 'json'

module Cacheable

  module CacheAdapters

    # Adapter that adds JSON serialization functionality to save and load in files.
    # Also adds contexts linked to keys being fetched to support more complex cache-invalidation schemes.
    # This works only if:
    # * The cached values are JSON serializable.
    # * The cache keys are strings.
    # * The context information is JSON serializable.
    class PersistentJsonAdapter < MemoryAdapter

      # Fetch a key with the givien cache options
      #
      # Parameters::
      # * *key* (String): Key to be fetched
      # * *options* (Hash): Cache options. The following options are interpreted by this fetch:
      #   * *invalidate_if* (Proc): Code called to know if the cache should be invalidated for a given key:
      #     * Parameters::
      #       * *key* (String): The key for which we check the cache invalidation
      #       * *options* (Hash): Cache options linked to this key
      #       * *key_context* (Hash): Context linked to this key, that can be set using the update_context_after_fetch callback.
      #     * Result::
      #       * Boolean: Should we invalidate the cached value of this key?
      #   * *update_context_after_fetch* (Proc): Code called when the value has been fetched for real (without cache), used to update the context
      #     * Parameters::
      #       * *key* (String): The key for which we just fetched the value
      #       * *value* (Object): The value that has just been fetched
      #       * *options* (Hash): Cache options linked to this key
      #       * *key_context* (Hash): Context linked to this key, that is supposed to be updated in place by this callback
      # * CodeBlock: Code called to fetch the value if not in the cache
      # Result::
      # * Object: The value for this key
      def fetch(key, options = {})
        context[key] = {} unless context.key?(key)
        key_context = context[key]
        delete(key) if options[:invalidate_if]&.call(key, options, key_context)
        return read(key) if exist?(key)

        value = yield
        options[:update_context_after_fetch]&.call(key, value, options, key_context)
        write(key, value)
      end

      # Clear the cache
      def clear
        @context = {}
        super
      end

      private

      attr_reader :context

    end

  end

end
