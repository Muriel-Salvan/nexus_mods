class NexusMods

  # Simple key/value file cache
  class FileCache

    # Constructor
    #
    # Parameters::
    # * *file* (String): File to use as a cache
    def initialize(file)
      @file = file
      @cache_content = File.exist?(file) ? JSON.parse(File.read(file)) : {}
    end

    # Dump the cache in file
    def dump
      File.write(@file, @cache_content.to_json)
    end

    # Get the cache content as a Hash
    #
    # Result::
    # * Hash<String, Object>: Cache content
    def to_h
      @cache_content
    end

    # Is a given key present in the cache?
    #
    # Parameters::
    # * *key* (String): The key
    # Result::
    # * Boolean: Is a given key present in the cache?
    def key?(key)
      @cache_content.key?(key)
    end

    # Read a key from the cache
    #
    # Parameters:
    # * *key* (String): The cache key
    # Result::
    # * Object or nil: JSON-serializable object storing the value, or nil in case of cache-miss
    def read(key)
      @cache_content.key?(key) ? @cache_content[key] : nil
    end

    alias [] read

    # Write a key/value in the cache
    #
    # Parameters:
    # * *key* (String): The key
    # * *value* (Object): JSON-serializable object storing the value
    def write(key, value)
      @cache_content[key] = value
    end

    alias []= write

    # Delete a key in the cache
    #
    # Parameters:
    # * *key* (String): The key
    def delete(key)
      @cache_content.delete(key)
    end

  end

end
