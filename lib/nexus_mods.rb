require 'json'
require 'time'
require 'tmpdir'
require 'nexus_mods/api_client'
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
  # * *api_cache_expiry* (Hash<Symbol,Integer>): Expiry times in seconds, per expiry key. Possible keys are:
  #   * *games*: Expiry associated to queries on games [default: 1 day]
  #   * *mod*: Expiry associated to queries on mod [default: 1 day]
  #   * *mod_files*: Expiry associated to queries on mod files [default: 1 day]
  # * *api_cache_file* (String): File used to store the NexusMods API cache, or nil for no cache [default: "#{Dir.tmpdir}/nexus_mods_api_cache.json"]
  # * *logger* (Logger): The logger to be used for log messages [default: Logger.new(STDOUT)]
  def initialize(
    api_key: nil,
    game_domain_name: 'skyrimspecialedition',
    mod_id: 1,
    file_id: 1,
    http_cache_file: "#{Dir.tmpdir}/nexus_mods_http_cache.json",
    api_cache_expiry: {},
    api_cache_file: "#{Dir.tmpdir}/nexus_mods_api_cache.json",
    logger: Logger.new($stdout)
  )
    @game_domain_name = game_domain_name
    @mod_id = mod_id
    @file_id = file_id
    @logger = logger
    @premium = false
    @api_client = ApiClient.new(
      api_key:,
      http_cache_file:,
      api_cache_expiry:,
      api_cache_file:,
      logger:
    )

    # Check that the key is correct and know if the user is premium
    begin
      @premium = @api_client.api('users/validate')['is_premium?']
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
    api_limits_headers = @api_client.http('users/validate').headers
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
  # Parameters::
  # * *clear_cache* (Boolean): Should we clear the API cache for this resource? [default: false]
  # Result::
  # * Array<Game>: List of games
  def games(clear_cache: false)
    @api_client.api('games', clear_cache:).map do |game_json|
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
  end

  # Get information about a mod
  #
  # Parameters::
  # * *game_domain_name* (String): Game domain name to query by default [default: @game_domain_name]
  # * *mod_id* (Integer): The mod ID [default: @mod_id]
  # * *clear_cache* (Boolean): Should we clear the API cache for this resource? [default: false]
  # Result::
  # * Mod: Mod information
  def mod(game_domain_name: @game_domain_name, mod_id: @mod_id, clear_cache: false)
    mod_json = @api_client.api("games/#{game_domain_name}/mods/#{mod_id}", clear_cache:)
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
  # * *clear_cache* (Boolean): Should we clear the API cache for this resource? [default: false]
  # Result::
  # * Array<ModFile>: List of mod's files
  def mod_files(game_domain_name: @game_domain_name, mod_id: @mod_id, clear_cache: false)
    @api_client.api("games/#{game_domain_name}/mods/#{mod_id}/files", clear_cache:)['files'].map do |file_json|
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
  end

end
