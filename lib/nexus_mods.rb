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
require 'nexus_mods/api/mod_updates'

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
  # * *api_cache_expiry* (Hash<Symbol,Integer>): Expiry times in seconds, per expiry key. Possible keys are:
  #   * *games*: Expiry associated to queries on games [default: 1 day]
  #   * *mod*: Expiry associated to queries on mod [default: 1 day]
  #   * *mod_files*: Expiry associated to queries on mod files [default: 1 day]
  # * *api_cache_file* (String): File used to store the NexusMods API cache, or nil for no cache [default: "#{Dir.tmpdir}/nexus_mods_api_cache.json"]
  # * *logger* (Logger): The logger to be used for log messages [default: Logger.new(STDOUT)]
  # * *log_level* (Symbol): The logger level to be set [default: :info]
  def initialize(
    api_key: nil,
    game_domain_name: 'skyrimspecialedition',
    mod_id: 1,
    file_id: 1,
    api_cache_expiry: {},
    api_cache_file: "#{Dir.tmpdir}/nexus_mods_api_cache.json",
    logger: Logger.new($stdout),
    log_level: :info
  )
    @game_domain_name = game_domain_name
    @mod_id = mod_id
    @file_id = file_id
    @logger = logger
    @logger.level = log_level
    @premium = false
    @api_client = ApiClient.new(
      api_key:,
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
      nexus_mods: self,
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
              nexus_mods: self,
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
        nexus_mods: self,
        id: game_json['id'],
        name: game_json['name'],
        forum_url: game_json['forum_url'],
        nexusmods_url: game_json['nexusmods_url'],
        genre: game_json['genre'],
        domain_name: game_json['domain_name'],
        approved_date: Time.at(game_json['approved_date']).utc,
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

  # Get the cached timestamp of the list of games
  #
  # Result::
  # * Time or nil: Freshness time of the data in the API cache, or nil if not present in the cache
  def games_cache_timestamp
    @api_client.api_cache_timestamp('games')
  end

  # Set the cached timestamp of the list of games.
  # This should be used only to update the cache timestamp of a resource we know is still up-to-date without fetching the resource for real again.
  #
  # Parameters::
  # * *cache_timestamp* (Time): The cache timestamp to set for this resource
  def set_games_cache_timestamp(cache_timestamp:)
    @api_client.set_api_cache_timestamp('games', cache_timestamp:)
  end

  # Get information about a mod
  #
  # Parameters::
  # * *game_domain_name* (String): Game domain name to query by default [default: @game_domain_name]
  # * *mod_id* (Integer): The mod ID [default: @mod_id]
  # * *clear_cache* (Boolean): Should we clear the API cache for this resource? [default: false]
  # * *check_updates* (Boolean): Should we check updates?
  #   If yes then an extra call to updated_mods may be done to check for updates before retrieving the mod information.
  #   In case the mod was previously retrieved and may be in an old cache, then using this will optimize the calls to NexusMods API to the minimum.
  # Result::
  # * Mod: Mod information
  def mod(game_domain_name: @game_domain_name, mod_id: @mod_id, clear_cache: false, check_updates: false)
    mod_cache_up_to_date?(game_domain_name:, mod_id:) if check_updates
    mod_json = @api_client.api("games/#{game_domain_name}/mods/#{mod_id}", clear_cache:)
    Api::Mod.new(
      nexus_mods: self,
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
        nexus_mods: self,
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

  # Get the cached timestamp of a mod information
  #
  # Parameters::
  # * *game_domain_name* (String): Game domain name to query by default [default: @game_domain_name]
  # * *mod_id* (Integer): The mod ID [default: @mod_id]
  # Result::
  # * Time or nil: Freshness time of the data in the API cache, or nil if not present in the cache
  def mod_cache_timestamp(game_domain_name: @game_domain_name, mod_id: @mod_id)
    @api_client.api_cache_timestamp("games/#{game_domain_name}/mods/#{mod_id}")
  end

  # Set the cached timestamp of a mod information.
  # This should be used only to update the cache timestamp of a resource we know is still up-to-date without fetching the resource for real again.
  #
  # Parameters::
  # * *game_domain_name* (String): Game domain name to query by default [default: @game_domain_name]
  # * *mod_id* (Integer): The mod ID [default: @mod_id]
  # * *cache_timestamp* (Time): The cache timestamp to set for this resource
  def set_mod_cache_timestamp(cache_timestamp:, game_domain_name: @game_domain_name, mod_id: @mod_id)
    @api_client.set_api_cache_timestamp("games/#{game_domain_name}/mods/#{mod_id}", cache_timestamp:)
  end

  # Get files belonging to a mod
  #
  # Parameters::
  # * *game_domain_name* (String): Game domain name to query by default [default: @game_domain_name]
  # * *mod_id* (Integer): The mod ID [default: @mod_id]
  # * *clear_cache* (Boolean): Should we clear the API cache for this resource? [default: false]
  # * *check_updates* (Boolean): Should we check updates?
  #   If yes then an extra call to updated_mods may be done to check for updates before retrieving the mod information.
  #   In case the mod files were previously retrieved and may be in an old cache, then using this will optimize the calls to NexusMods API to the minimum.
  # Result::
  # * Array<ModFile>: List of mod's files
  def mod_files(game_domain_name: @game_domain_name, mod_id: @mod_id, clear_cache: false, check_updates: false)
    mod_files_cache_up_to_date?(game_domain_name:, mod_id:) if check_updates
    @api_client.api("games/#{game_domain_name}/mods/#{mod_id}/files", clear_cache:)['files'].map do |file_json|
      Api::ModFile.new(
        nexus_mods: self,
        game_domain_name:,
        mod_id:,
        ids: file_json['id'],
        uid: file_json['uid'],
        id: file_json['file_id'],
        name: file_json['name'],
        version: file_json['version'],
        category_id: file_json['category_id'],
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

  # Get the cached timestamp of a mod files information
  #
  # Parameters::
  # * *game_domain_name* (String): Game domain name to query by default [default: @game_domain_name]
  # * *mod_id* (Integer): The mod ID [default: @mod_id]
  # Result::
  # * Time or nil: Freshness time of the data in the API cache, or nil if not present in the cache
  def mod_files_cache_timestamp(game_domain_name: @game_domain_name, mod_id: @mod_id)
    @api_client.api_cache_timestamp("games/#{game_domain_name}/mods/#{mod_id}/files")
  end

  # Set the cached timestamp of a mod files information.
  # This should be used only to update the cache timestamp of a resource we know is still up-to-date without fetching the resource for real again.
  #
  # Parameters::
  # * *game_domain_name* (String): Game domain name to query by default [default: @game_domain_name]
  # * *mod_id* (Integer): The mod ID [default: @mod_id]
  # * *cache_timestamp* (Time): The cache timestamp to set for this resource
  def set_mod_files_cache_timestamp(cache_timestamp:, game_domain_name: @game_domain_name, mod_id: @mod_id)
    @api_client.set_api_cache_timestamp("games/#{game_domain_name}/mods/#{mod_id}/files", cache_timestamp:)
  end

  # Get a list of updated mod ids since a given time
  #
  # Parameters::
  # * *game_domain_name* (String): Game domain name to query by default [default: @game_domain_name]
  # * *since* (Symbol): The time from which we look for updated mods [default: :one_day]
  #   Possible values are:
  #   * *one_day*: Since 1 day
  #   * *one_week*: Since 1 week
  #   * *one_month*: Since 1 month
  # * *clear_cache* (Boolean): Should we clear the API cache for this resource? [default: false]
  # Result::
  # * Array<ModUpdates>: Mod's updates information
  def updated_mods(game_domain_name: @game_domain_name, since: :one_day, clear_cache: false)
    @api_client.api("games/#{game_domain_name}/mods/updated", parameters: period_to_url_params(since), clear_cache:).map do |updated_mod_json|
      Api::ModUpdates.new(
        nexus_mods: self,
        game_domain_name:,
        mod_id: updated_mod_json['mod_id'],
        latest_file_update: Time.at(updated_mod_json['latest_file_update']).utc,
        latest_mod_activity: Time.at(updated_mod_json['latest_mod_activity']).utc
      )
    end
  end

  # Get the cached timestamp of updated mod ids
  #
  # Parameters::
  # * *game_domain_name* (String): Game domain name to query by default [default: @game_domain_name]
  # * *since* (Symbol): The time from which we look for updated mods [default: :one_day]
  #   Possible values are:
  #   * *one_day*: Since 1 day
  #   * *one_week*: Since 1 week
  #   * *one_month*: Since 1 month
  # Result::
  # * Time or nil: Freshness time of the data in the API cache, or nil if not present in the cache
  def updated_mods_cache_timestamp(game_domain_name: @game_domain_name, since: :one_day)
    @api_client.api_cache_timestamp("games/#{game_domain_name}/mods/updated", parameters: period_to_url_params(since))
  end

  # Set the cached timestamp of updated mod ids.
  # This should be used only to update the cache timestamp of a resource we know is still up-to-date without fetching the resource for real again.
  #
  # Parameters::
  # * *game_domain_name* (String): Game domain name to query by default [default: @game_domain_name]
  # * *since* (Symbol): The time from which we look for updated mods [default: :one_day]
  #   Possible values are:
  #   * *one_day*: Since 1 day
  #   * *one_week*: Since 1 week
  #   * *one_month*: Since 1 month
  # * *cache_timestamp* (Time): The cache timestamp to set for this resource
  def set_updated_mods_cache_timestamp(cache_timestamp:, game_domain_name: @game_domain_name, since: :one_day)
    @api_client.set_api_cache_timestamp("games/#{game_domain_name}/mods/updated", parameters: period_to_url_params(since), cache_timestamp:)
  end

  # Does a given mod id have fresh information in our cache?
  # This may fire queries to the updated mods API to get info from NexusMods about the latest updated mods.
  # If we know the mod is up-to-date, then its mod information cache timestamp will be set to the time when we checked for updates if it was greater than the cache date.
  #
  # Here is the algorithm:
  # If it is not in the cache, then it is not up-to-date.
  # Otherwise, the API allows us to know if it has been updated up to 1 month in the past.
  # Therefore if the current cache timestamp is older than 1 month, assume that it has to be updated.
  # Otherwise query the API to know the latest updated mods since 1 month:
  # * If the mod ID is not there, then it is up-to-date.
  # * If the mod ID is there, then check if our cache timestamp is older than the last update timestamp from NexusMods.
  #
  # Parameters::
  # * *game_domain_name* (String): Game domain name to query by default [default: @game_domain_name]
  # * *mod_id* (Integer): The mod ID [default: @mod_id]
  # Result::
  # * Boolean: Is the mod cache up-to-date?
  def mod_cache_up_to_date?(game_domain_name: @game_domain_name, mod_id: @mod_id)
    existing_cache_timestamp = mod_cache_timestamp(game_domain_name:, mod_id:)
    mod_up_to_date =
      if existing_cache_timestamp.nil? || existing_cache_timestamp < Time.now - (30 * 24 * 60 * 60)
        # It's not in the cache
        # or it's older than 1 month
        false
      else
        found_mod_updates = updated_mods(game_domain_name:, since: :one_month).find { |mod_updates| mod_updates.mod_id == mod_id }
        # true if it has not been updated on NexusMods since 1 month
        # or our cache timestamp is more recent
        found_mod_updates.nil? || found_mod_updates.latest_mod_activity < existing_cache_timestamp
      end
    if mod_up_to_date
      update_time = updated_mods_cache_timestamp(game_domain_name:, since: :one_month)
      set_mod_cache_timestamp(cache_timestamp: update_time, game_domain_name:, mod_id:) if update_time > existing_cache_timestamp
    end
    mod_up_to_date
  end

  # Does a given mod id have fresh files information in our cache?
  # This may fire queries to the updated mods API to get info from NexusMods about the latest updated mods.
  # If we know the mod is up-to-date, then its mod information cache timestamp will be set to the time when we checked for updates if it was greater than the cache date.
  #
  # Here is the algorithm:
  # If it is not in the cache, then it is not up-to-date.
  # Otherwise, the API allows us to know if it has been updated up to 1 month in the past.
  # Therefore if the current cache timestamp is older than 1 month, assume that it has to be updated.
  # Otherwise query the API to know the latest updated mods since 1 month:
  # * If the mod ID is not there, then it is up-to-date.
  # * If the mod ID is there, then check if our cache timestamp is older than the last update timestamp from NexusMods.
  #
  # Parameters::
  # * *game_domain_name* (String): Game domain name to query by default [default: @game_domain_name]
  # * *mod_id* (Integer): The mod ID [default: @mod_id]
  # Result::
  # * Boolean: Is the mod cache up-to-date?
  def mod_files_cache_up_to_date?(game_domain_name: @game_domain_name, mod_id: @mod_id)
    existing_cache_timestamp = mod_files_cache_timestamp(game_domain_name:, mod_id:)
    mod_up_to_date =
      if existing_cache_timestamp.nil? || existing_cache_timestamp < Time.now - (30 * 24 * 60 * 60)
        # It's not in the cache
        # or it's older than 1 month
        false
      else
        found_mod_updates = updated_mods(game_domain_name:, since: :one_month).find { |mod_updates| mod_updates.mod_id == mod_id }
        # true if it has not been updated on NexusMods since 1 month
        # or our cache timestamp is more recent
        found_mod_updates.nil? || found_mod_updates.latest_file_update < existing_cache_timestamp
      end
    if mod_up_to_date
      update_time = updated_mods_cache_timestamp(game_domain_name:, since: :one_month)
      set_mod_files_cache_timestamp(cache_timestamp: update_time, game_domain_name:, mod_id:) if update_time > existing_cache_timestamp
    end
    mod_up_to_date
  end

  private

  # Get the URL parameters from the required period
  #
  # Parameters::
  # * *since* (Symbol): The time from which we look for updated mods
  #   Possible values are:
  #   * *one_day*: Since 1 day
  #   * *one_week*: Since 1 week
  #   * *one_month*: Since 1 month
  # Result::
  # * Hash<Symbol,Object>: Corresponding URL parameters
  def period_to_url_params(since)
    nexus_mods_period = {
      one_day: '1d',
      one_week: '1w',
      one_month: '1m'
    }[since]
    raise "Unknown time stamp: #{since}" if nexus_mods_period.nil?

    { period: nexus_mods_period }
  end

end
