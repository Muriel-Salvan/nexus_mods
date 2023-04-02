require 'addressable/uri'
require 'json'
require 'time'
require 'tmpdir'
require 'faraday'
require 'faraday-http-cache'
require 'nexus_mods/file_cache'
require 'nexus_mods/api/api_limits'
require 'nexus_mods/api/category'
require 'nexus_mods/api/game'
require 'nexus_mods/api/user'
require 'nexus_mods/api/mod'
require 'nexus_mods/api/mod_file'

# Ruby API to access NexusMods REST API
class NexusMods

  # Error raised by the API calls
  class ApiError < RuntimeError
  end

  # Error raised when the API calls have exceed their usage limits
  class LimitsExceededError < ApiError
  end

  # Error raised when the API key is invalid
  class InvalidApiKeyError < ApiError
  end

  # The default game domain name to be queried
  #   String
  attr_accessor :game_domain_name

  # The default mod id to be queried
  #   Integer
  attr_accessor :mod_id

  # Constructor
  #
  # Parameters::
  # * *api_key* (String or nil): The API key to be used, or nil for another authentication [default: nil]
  # * *game_domain_name* (String): Game domain name to query by default [default: 'skyrimspecialedition']
  # * *mod_id* (Integer): Mod to query by default [default: 1]
  # * *file_id* (Integer): File to query by default [default: 1]
  # * *http_cache_file* (String): File used to store the HTTP cache, or nil for no cache [default: "#{Dir.tmpdir}/nexus_mods_http_cache.json"]
  # * *games_cache_file* (String): File used to store the games cache, or nil for no cache [default: nil]
  # * *mods_cache_file* (String): File used to store the mods cache, or nil for no cache [default: nil]
  # * *logger* (Logger): The logger to be used for log messages [default: Logger.new(STDOUT)]
  def initialize(
    api_key: nil,
    game_domain_name: 'skyrimspecialedition',
    mod_id: 1,
    file_id: 1,
    http_cache_file: "#{Dir.tmpdir}/nexus_mods_http_cache.json",
    games_cache_file: nil,
    mods_cache_file: nil,
    logger: Logger.new($stdout)
  )
    @api_key = api_key
    @game_domain_name = game_domain_name
    @mod_id = mod_id
    @file_id = file_id
    @http_cache = http_cache_file.nil? ? nil : FileCache.new(http_cache_file)
    @games_cache = games_cache_file.nil? ? nil : FileCache.new(games_cache_file)
    @mods_cache = mods_cache_file.nil? ? nil : FileCache.new(mods_cache_file)
    @logger = logger
    @premium = false
    # Initialize our HTTP client
    @http_client = Faraday.new do |builder|
      # Indicate that the cache is not shared, meaning that private resources (depending on the session) can be cached as we consider only 1 user is using it for a given file cache.
      # Use Marshal serializer as some URLs can't get decoded correctly due to UTF-8 issues
      builder.use :http_cache,
        store: @http_cache,
        shared_cache: false,
        serializer: Marshal
      builder.adapter Faraday.default_adapter
    end
    # Check that the key is correct and know if the user is premium
    begin
      @premium = api('users/validate')['is_premium?']
    rescue LimitsExceededError
      raise
    rescue ApiError
      raise InvalidApiKeyError, 'Invalid API key'
    end
  end

  # Get limits of API calls.
  # This call does not count in the limits.
  #
  # Result::
  # * ApiLimits: API calls limits
  def api_limits
    api_limits_headers = http('users/validate').headers
    Api::ApiLimits.new(
      daily_limit: Integer(api_limits_headers['x-rl-daily-limit']),
      daily_remaining: Integer(api_limits_headers['x-rl-daily-remaining']),
      daily_reset: Time.parse(api_limits_headers['x-rl-daily-reset']).utc,
      hourly_limit: Integer(api_limits_headers['x-rl-hourly-limit']),
      hourly_remaining: Integer(api_limits_headers['x-rl-hourly-remaining']),
      hourly_reset: Time.parse(api_limits_headers['x-rl-hourly-reset']).utc
    )
  end

  # Get the list of games
  #
  # Result::
  # * Array<Game>: List of games
  def games
    # with_cache(@games_cache, 'games') do
    api('games').map do |game_json|
      # First create categories tree
      # Hash<Integer, [Category, Integer]>: Category and its parent category id, per category id
      categories = game_json['categories'].to_h do |category_json|
        category_id = category_json['category_id']
        [
          category_id,
          [
            Api::Category.new(
              id: category_id,
              name: category_json['name']
            ),
            category_json['parent_category']
          ]
        ]
      end
      categories.each_value do |(category, parent_category_id)|
        # Ignore missing parent categories: this situation happens.
        category.parent_category = categories[parent_category_id]&.first if parent_category_id
      end
      Api::Game.new(
        id: game_json['id'],
        name: game_json['name'],
        forum_url: game_json['forum_url'],
        nexusmods_url: game_json['nexusmods_url'],
        genre: game_json['genre'],
        domain_name: game_json['domain_name'],
        approved_date: Time.at(game_json['approved_date']),
        files_count: game_json['file_count'],
        files_views: game_json['file_views'],
        files_endorsements: game_json['file_endorsements'],
        downloads_count: game_json['downloads'],
        authors_count: game_json['authors'],
        mods_count: game_json['mods'],
        categories: categories.values.map { |(category, _parent_category_id)| category }
      )
    end
    # end
  end

  # Get information about a mod
  #
  # Parameters::
  # * *game_domain_name* (String): Game domain name to query by default [default: @game_domain_name]
  # * *mod_id* (Integer): The mod ID [default: @mod_id]
  # Result::
  # * Mod: Mod information
  def mod(game_domain_name: @game_domain_name, mod_id: @mod_id)
    # with_cache(@mods_cache, "#{game_domain_name}/#{mod_id}/info") do
    mod_json = api "games/#{game_domain_name}/mods/#{mod_id}"
    Api::Mod.new(
      uid: mod_json['uid'],
      mod_id: mod_json['mod_id'],
      game_id: mod_json['game_id'],
      allow_rating: mod_json['allow_rating'],
      domain_name: mod_json['domain_name'],
      category_id: mod_json['category_id'],
      version: mod_json['version'],
      created_time: Time.parse(mod_json['created_time']),
      updated_time: Time.parse(mod_json['updated_time']),
      author: mod_json['author'],
      contains_adult_content: mod_json['contains_adult_content'],
      status: mod_json['status'],
      available: mod_json['available'],
      uploader: Api::User.new(
        member_id: mod_json['user']['member_id'],
        member_group_id: mod_json['user']['member_group_id'],
        name: mod_json['user']['name'],
        profile_url: mod_json['uploaded_users_profile_url']
      ),
      name: mod_json['name'],
      summary: mod_json['summary'],
      description: mod_json['description'],
      picture_url: mod_json['picture_url'],
      downloads_count: mod_json['mod_downloads'],
      unique_downloads_count: mod_json['mod_unique_downloads'],
      endorsements_count: mod_json['endorsement_count']
    )
    # end
  end

  # Enum of file categories from the API
  FILE_CATEGORIES = {
    1 => :main,
    2 => :patch,
    3 => :optional,
    4 => :old,
    6 => :deleted
  }

  # Get files belonging to a mod
  #
  # Parameters::
  # * *game_domain_name* (String): Game domain name to query by default [default: @game_domain_name]
  # * *mod_id* (Integer): The mod ID [default: @mod_id]
  # Result::
  # * Array<ModFile>: List of mod's files
  def mod_files(game_domain_name: @game_domain_name, mod_id: @mod_id)
    # with_cache(@mods_cache, "#{game_domain_name}/#{mod_id}/files") do
    api("games/#{game_domain_name}/mods/#{mod_id}/files")['files'].map do |file_json|
      category_id = FILE_CATEGORIES[file_json['category_id']]
      raise "Unknown file category: #{file_json['category_id']}" if category_id.nil?

      Api::ModFile.new(
        ids: file_json['id'],
        uid: file_json['uid'],
        id: file_json['file_id'],
        name: file_json['name'],
        version: file_json['version'],
        category_id:,
        category_name: file_json['category_name'],
        is_primary: file_json['is_primary'],
        size: file_json['size_in_bytes'],
        file_name: file_json['file_name'],
        uploaded_time: Time.parse(file_json['uploaded_time']),
        mod_version: file_json['mod_version'],
        external_virus_scan_url: file_json['external_virus_scan_url'],
        description: file_json['description'],
        changelog_html: file_json['changelog_html'],
        content_preview_url: file_json['content_preview_link']
      )
    end
    # end
  end

  private

  # # Get games list from cache, with the date of cache refresh.
  # #
  # # Result::
  # # * Object or nil: Games cache, or nil if nothing in cache
  # # * Time or nil: Time when the cache was refreshed, or nil if nothing in cache
  # def cached_games
  #   @games_cache.nil? || !@games_cache.key?('games') ? [nil, nil] : [@games_cache['games']['value'], @games_cache['games']['date']]
  # end

  # # Get mods list from cache having their info cached, with their date of cache refresh.
  # #
  # # Parameters::
  # # * *game_domain_name* (String): Game domain name to query by default [default: @game_domain_name]
  # # Result::
  # # * Hash<Integer,Time>: List of mod IDs and their corresponding cache time
  # def cached_mods_info(game_domain_name: @game_domain_name)
  #   cached_mods_for :info, game_domain_name: game_domain_name
  # end

  # # Get mods list from cache having their files cached, with their date of cache refresh.
  # #
  # # Parameters::
  # # * *game_domain_name* (String): Game domain name to query by default [default: @game_domain_name]
  # # Result::
  # # * Hash<Integer,Time>: List of mod IDs and their corresponding cache time
  # def cached_mods_files(game_domain_name: @game_domain_name)
  #   cached_mods_for :files, game_domain_name: game_domain_name
  # end

  # # Remove cached games info
  # def remove_cached_games
  #   @games_cache.delete('games')
  # end

  # # Remove cached mod info of a given mod id
  # #
  # # Parameters::
  # # * *game_domain_name* (String): Game domain name to query by default [default: @game_domain_name]
  # # * *mod_id* (Integer): The mod ID [default: @mod_id]
  # def remove_cached_mod_info(game_domain_name: @game_domain_name, mod_id: @mod_id)
  #   @mods_cache.delete("#{game_domain_name}/#{mod_id}/info")
  # end

  # # Remove cached mod files of a given mod id
  # #
  # # Parameters::
  # # * *game_domain_name* (String): Game domain name to query by default [default: @game_domain_name]
  # # * *mod_id* (Integer): The mod ID [default: @mod_id]
  # def remove_cached_mod_files(game_domain_name: @game_domain_name, mod_id: @mod_id)
  #   @mods_cache.delete("#{game_domain_name}/#{mod_id}/files")
  # end

  # # Dump caches in files.
  # def dump_caches
  #   @http_cache.dump unless @http_cache.nil?
  #   @mods_cache.dump unless @mods_cache.nil?
  #   @games_cache.dump unless @games_cache.nil?
  # end

  # # Get mods list from cache, with their date of cache refresh, for a given cached mods property.
  # #
  # # Parameters::
  # # * *cached_property* (Symbol): Mod cached property to check for (for example :info, :files...)
  # # * *game_domain_name* (String): Game domain name to query by default [default: @game_domain_name]
  # # Result::
  # # * Hash<Integer,Time>: List of mod IDs and their corresponding cache time
  # def cached_mods_for(cached_property, game_domain_name: @game_domain_name)
  #   mods = {}
  #   unless @mods_cache.nil?
  #     cached_property_str = cached_property.to_s
  #     @mods_cache.to_h.each do |mod_cache_key, mod_cache_info|
  #       _game_id, mod_id, property = mod_cache_key.split('/')
  #       mods[mod_id.to_i] = Time.parse(mod_cache_info['date']) if property = cached_property_str
  #     end
  #   end
  #   mods
  # end

  # # Cache the execution of a code block.
  # # Store along in the cache when as the code block been executed for the last time.
  # #
  # # Parameters::
  # # * *cache* (FileCache or nil): The cache to be used for caching, or nil if no cache
  # # * *key* (String): The key to be used in this cache
  # # * Proc: Code called in case of cache miss
  # #   * Result::
  # #     * Object: JSON-serializable object that is cached
  # # Result::
  # # * Object: JSON-serializable object, either the cache result or the code block execution result
  # def with_cache(cache, key)
  #   if cache.nil?
  #     yield
  #   elsif cache.key?(key)
  #     cache[key]['value']
  #   else
  #     value = yield
  #     cache[key] = {
  #       'value' => value,
  #       'date' => Time.now.utc.strftime('%F %T UTC')
  #     }
  #     value
  #   end
  # end

  # Send an HTTP request to the API and get back the answer as a JSON
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
