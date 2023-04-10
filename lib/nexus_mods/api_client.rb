require 'fileutils'
require 'faraday'
require 'faraday-http-cache'
require 'nexus_mods/file_cache'
require 'nexus_mods/cacheable_api'

class NexusMods

  # Base class handling HTTP calls to the NexusMods API.
  # Handle caching if needed.
  class ApiClient

    include CacheableApi

    # Default expiry times, in seconds
    DEFAULT_API_CACHE_EXPIRY = {
      games: 24 * 60 * 60,
      mod: 24 * 60 * 60,
      mod_files: 24 * 60 * 60
    }

    # Constructor
    #
    # Parameters::
    # * *api_key* (String or nil): The API key to be used, or nil for another authentication [default: nil]
    # * *http_cache_file* (String): File used to store the HTTP cache, or nil for no cache [default: "#{Dir.tmpdir}/nexus_mods_http_cache.json"]
    # * *api_cache_expiry* (Hash<Symbol,Integer>): Expiry times in seconds, per expiry key. Possible keys are:
    #   * *games*: Expiry associated to queries on games [default: 1 day]
    #   * *mod*: Expiry associated to queries on mod [default: 1 day]
    #   * *mod_files*: Expiry associated to queries on mod files [default: 1 day]
    # * *api_cache_file* (String): File used to store the NexusMods API cache, or nil for no cache [default: "#{Dir.tmpdir}/nexus_mods_api_cache.json"]
    # * *logger* (Logger): The logger to be used for log messages [default: Logger.new(STDOUT)]
    def initialize(
      api_key: nil,
      http_cache_file: "#{Dir.tmpdir}/nexus_mods_http_cache.json",
      api_cache_expiry: DEFAULT_API_CACHE_EXPIRY,
      api_cache_file: "#{Dir.tmpdir}/nexus_mods_api_cache.json",
      logger: Logger.new($stdout)
    )
      @api_key = api_key
      @api_cache_expiry = DEFAULT_API_CACHE_EXPIRY.merge(api_cache_expiry)
      @api_cache_file = api_cache_file
      ApiClient.api_client = self
      @logger = logger
      # Initialize our HTTP client
      @http_cache = http_cache_file.nil? ? nil : FileCache.new(http_cache_file)
      @http_client = Faraday.new do |builder|
        # Indicate that the cache is not shared, meaning that private resources (depending on the session) can be cached as we consider only 1 user is using it for a given file cache.
        # Use Marshal serializer as some URLs can't get decoded correctly due to UTF-8 issues
        builder.use :http_cache,
                    store: @http_cache,
                    shared_cache: false,
                    serializer: Marshal
        builder.adapter Faraday.default_adapter
      end
      Cacheable.cache_adapter = :persistent_json
      load_api_cache
    end

    # Send an HTTP request to the API and get back the answer as a JSON.
    # Use caching.
    #
    # Parameters::
    # * *path* (String): API path to contact (from v1/ and without .json)
    # * *verb* (Symbol): Verb to be used (:get, :post...) [default: :get]
    # Result::
    # * Object: The JSON response
    def api(path, verb: :get)
      res = http(path, verb:)
      json = JSON.parse(res.body)
      uri = api_uri(path)
      @logger.debug "[API call] - #{verb} #{uri} => #{res.status}\n#{
          JSON.
            pretty_generate(json).
            split("\n").
            map { |line| "  #{line}" }.
            join("\n")
        }\n#{
          res.
            headers.
            map { |header, value| "  #{header}: #{value}" }.
            join("\n")
        }"
      case res.status
      when 200
        # Happy
      when 429
        # Some limits of the API have been reached
        raise LimitsExceededError, "Exceeding limits of API calls: #{res.headers.select { |header, _value| header =~ /^x-rl-.+$/ }}"
      else
        raise ApiError, "API #{uri} returned error code #{res.status}" unless res.status == '200'
      end
      json
    end
    cacheable_api(
      :api,
      expiry_from_key: proc do |key|
        # Example of keys:
        # NexusMods::ApiClient/api/games
        # NexusMods::ApiClient/api/games/skyrimspecialedition/mods/2014
        # NexusMods::ApiClient/api/games/skyrimspecialedition/mods/2014/files
        # NexusMods::ApiClient/api/users/validate
        key_components = key.split('/')[2..]
        case key_components[0]
        when 'games'
          if key_components[1].nil?
            ApiClient.api_client.api_cache_expiry[:games]
          else
            case key_components[2]
            when 'mods'
              case key_components[4]
              when nil
                ApiClient.api_client.api_cache_expiry[:mod]
              when 'files'
                ApiClient.api_client.api_cache_expiry[:mod_files]
              else
                raise "Unknown API path: #{key}"
              end
            else
              raise "Unknown API path: #{key}"
            end
          end
        when 'users'
          # Don't cache this path as it is used to know API limits
          0
        else
          raise "Unknown API path: #{key}"
        end
      end,
      on_cache_update: proc do
        ApiClient.api_client.save_api_cache
      end
    )

    # Send an HTTP request to the API and get back the HTTP response
    #
    # Parameters::
    # * *path* (String): API path to contact (from v1/ and without .json)
    # * *verb* (Symbol): Verb to be used (:get, :post...) [default: :get]
    # Result::
    # * Faraday::Response: The HTTP response
    def http(path, verb: :get)
      @http_client.send(verb) do |req|
        req.url api_uri(path)
        req.headers['apikey'] = @api_key
        req.headers['User-Agent'] = "nexus_mods (#{RUBY_PLATFORM}) Ruby/#{RUBY_VERSION}"
      end
    end

    # Load the API cache if a file was given to this client
    def load_api_cache
      Cacheable.cache_adapter.load(@api_cache_file) if @api_cache_file && File.exist?(@api_cache_file)
    end

    # Save the API cache if a file was given to this client
    def save_api_cache
      return unless @api_cache_file

      FileUtils.mkdir_p(File.dirname(@api_cache_file))
      Cacheable.cache_adapter.save(@api_cache_file)
    end

    # Some attributes exposed for the cacheable feature to work
    attr_reader :api_cache_expiry

    private

    class << self

      # ApiClient: The API client to be used by the cacheable adapter (singleton pattern)
      attr_accessor :api_client

    end

    @api_client = nil

    # Get the real URI to query for a given API path
    #
    # Parameters::
    # * *path* (String): API path to contact (from v1/ and without .json)
    # Result::
    # * String: The URI
    def api_uri(path)
      "https://api.nexusmods.com/v1/#{path}.json"
    end

  end

end
