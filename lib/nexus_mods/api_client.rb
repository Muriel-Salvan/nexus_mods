require 'fileutils'
require 'faraday'
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
    # * *api_cache_expiry* (Hash<Symbol,Integer>): Expiry times in seconds, per expiry key. Possible keys are:
    #   * *games*: Expiry associated to queries on games [default: 1 day]
    #   * *mod*: Expiry associated to queries on mod [default: 1 day]
    #   * *mod_files*: Expiry associated to queries on mod files [default: 1 day]
    # * *api_cache_file* (String): File used to store the NexusMods API cache, or nil for no cache [default: "#{Dir.tmpdir}/nexus_mods_api_cache.json"]
    # * *logger* (Logger): The logger to be used for log messages [default: Logger.new(STDOUT)]
    def initialize(
      api_key: nil,
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
      @http_client = Faraday.new
      Cacheable.cache_adapter = :persistent_json
      load_api_cache
    end

    # Send an HTTP request to the API and get back the answer as a JSON.
    # Use caching.
    #
    # Parameters::
    # * *path* (String): API path to contact (from v1/ and without .json)
    # * *verb* (Symbol): Verb to be used (:get, :post...) [default: :get]
    # * *clear_cache* (Boolean): Should we clear the API cache for this resource? [default: false]
    # Result::
    # * Object: The JSON response
    def api(path, verb: :get, clear_cache: false)
      clear_cached_api_cache(path, verb:) if clear_cache
      cached_api(path, verb:)
    end

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

    # Send an HTTP request to the API and get back the answer as a JSON.
    # Use caching.
    #
    # Parameters::
    # * *path* (String): API path to contact (from v1/ and without .json)
    # * *verb* (Symbol): Verb to be used (:get, :post...) [default: :get]
    # Result::
    # * Object: The JSON response
    def cached_api(path, verb: :get)
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
      :cached_api,
      key_format: proc do |_target, _method_name, method_args, method_kwargs|
        "#{method_kwargs[:verb]}/#{method_args.first}"
      end,
      expiry_from_key: proc do |key|
        # Example of keys:
        # get/games
        # get/games/skyrimspecialedition/mods/2014
        # get/games/skyrimspecialedition/mods/2014/files
        # get/users/validate
        key_components = key.split('/')[1..]
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
