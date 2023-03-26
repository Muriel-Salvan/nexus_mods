require 'addressable/uri'
require 'json'
require 'time'
require 'tmpdir'
require 'faraday'
require 'nexus_mods/api_limits'
require 'nexus_mods/category'
require 'nexus_mods/game'
require 'nexus_mods/user'
require 'nexus_mods/mod'
require 'nexus_mods/mod_file'

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
  # * *logger* (Logger): The logger to be used for log messages [default: Logger.new(STDOUT)]
  def initialize(
    api_key: nil,
    game_domain_name: 'skyrimspecialedition',
    mod_id: 1,
    file_id: 1,
    logger: Logger.new($stdout)
  )
    @api_key = api_key
    @game_domain_name = game_domain_name
    @mod_id = mod_id
    @file_id = file_id
    @logger = logger
    @premium = false
    # Initialize our HTTP client
    @http_client = Faraday.new do |builder|
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
    ApiLimits.new(
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
    api('games').map do |game_json|
      # First create categories tree
      # Hash<Integer, [Category, Integer]>: Category and its parent category id, per category id
      categories = game_json['categories'].to_h do |category_json|
        category_id = category_json['category_id']
        [
          category_id,
          [
            Category.new(
              id: category_id,
              name: category_json['name']
            ),
            category_json['parent_category']
          ]
        ]
      end
      categories.each_value do |(category, parent_category_id)|
        category.parent_category = categories[parent_category_id].first if parent_category_id
      end
      Game.new(
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
  end

  # Get information about a mod
  #
  # Parameters::
  # * *game_domain_name* (String): Game domain name to query by default [default: @game_domain_name]
  # * *mod_id* (Integer): The mod ID [default: @mod_id]
  # Result::
  # * Mod: Mod information
  def mod(game_domain_name: @game_domain_name, mod_id: @mod_id)
    mod_json = api "games/#{game_domain_name}/mods/#{mod_id}"
    Mod.new(
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
      uploader: User.new(
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
    api("games/#{game_domain_name}/mods/#{mod_id}/files")['files'].map do |file_json|
      category_id = FILE_CATEGORIES[file_json['category_id']]
      raise "Unknown file category: #{file_json['category_id']}" if category_id.nil?

      ModFile.new(
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
  end

  private

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
