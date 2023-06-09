require 'nexus_mods/api/resource'

class NexusMods

  module Api

    # A NexusMods mod.
    # Attributes info can be taken from there:
    # * https://github.com/Nexus-Mods/node-nexus-api/blob/master/docs/interfaces/_types_.imodinfo.md
    class Mod < Resource

      attr_reader(
        *%i[
          uid
          mod_id
          game_id
          allow_rating
          domain_name
          category_id
          version
          created_time
          updated_time
          author
          contains_adult_content
          status
          available
          uploader
          name
          summary
          description
          picture_url
          downloads_count
          unique_downloads_count
          endorsements_count
        ]
      )

      # Constructor
      #
      # Parameters::
      # * *nexus_mods* (NexusMods): The NexusMods API instance that the resource can use to query for other resources
      # * *uid* (Integer): The mod's uid
      # * *mod_id* (Integer): The mod's id
      # * *game_id* (Integer): The mod's game id
      # * *allow_rating* (Boolean): Does this mod allow endorsements?
      # * *domain_name* (String): The mod's domain name
      # * *category_id* (String): The mod's category id
      # * *version* (String): The mod's version
      # * *created_time* (Time): The mod's creation time
      # * *updated_time* (Time): The mod's update time
      # * *author* (String): The mod's author
      # * *contains_adult_content* (Boolean): Does this mod contain adult content?
      # * *status* (String): The mod's status
      # * *available* (Boolean): Is the mod publicly available?
      # * *uploader* (User): The mod's uploader information
      # * *name* (String or nil): The mod's name, or nil if under moderation [default: nil]
      # * *summary* (String or nil): The mod's summary, or nil if none [default: nil]
      # * *description* (String or nil): The mod's description, or nil if none [default: nil]
      # * *picture_url* (String): The mod's picture_url [default: nil]
      # * *downloads_count* (Integer): The mod's downloads' count [default: 0]
      # * *unique_downloads_count* (Integer): The mod's unique downloads' count [default: 0]
      # * *endorsements_count* (Integer): The mod's endorsements' count [default: 0]
      def initialize(
        nexus_mods:,
        uid:,
        mod_id:,
        game_id:,
        allow_rating:,
        domain_name:,
        category_id:,
        version:,
        created_time:,
        updated_time:,
        author:,
        contains_adult_content:,
        status:,
        available:,
        uploader:,
        name: nil,
        summary: nil,
        description: nil,
        picture_url: nil,
        downloads_count: 0,
        unique_downloads_count: 0,
        endorsements_count: 0
      )
        super(nexus_mods:)
        @uid = uid
        @mod_id = mod_id
        @game_id = game_id
        @allow_rating = allow_rating
        @domain_name = domain_name
        @category_id = category_id
        @version = version
        @created_time = created_time
        @updated_time = updated_time
        @author = author
        @contains_adult_content = contains_adult_content
        @status = status
        @available = available
        @uploader = uploader
        @name = name
        @summary = summary
        @description = description
        @picture_url = picture_url
        @downloads_count = downloads_count
        @unique_downloads_count = unique_downloads_count
        @endorsements_count = endorsements_count
      end

      # Equality operator
      #
      # Parameters::
      # * *other* (Object): Other object to compare with
      # Result::
      # * Boolean: Are objects equal?
      def ==(other)
        other.is_a?(Mod) &&
          @uid == other.uid &&
          @mod_id == other.mod_id &&
          @game_id == other.game_id &&
          @allow_rating == other.allow_rating &&
          @domain_name == other.domain_name &&
          @category_id == other.category_id &&
          @version == other.version &&
          @created_time == other.created_time &&
          @updated_time == other.updated_time &&
          @author == other.author &&
          @contains_adult_content == other.contains_adult_content &&
          @status == other.status &&
          @available == other.available &&
          @uploader == other.uploader &&
          @name == other.name &&
          @summary == other.summary &&
          @description == other.description &&
          @picture_url == other.picture_url &&
          @downloads_count == other.downloads_count &&
          @unique_downloads_count == other.unique_downloads_count &&
          @endorsements_count == other.endorsements_count
      end

      # Get associated files information
      #
      # Result::
      # * Array<ModFile>: The list of mod files information
      def files
        @nexus_mods.mod_files(game_domain_name: domain_name, mod_id:)
      end

    end

  end

end
