require 'nexus_mods/api/resource'

class NexusMods

  module Api

    # A NexusMods mod updates.
    class ModUpdates < Resource

      attr_reader(
        *%i[
          game_domain_name
          mod_id
          latest_file_update
          latest_mod_activity
        ]
      )

      # Constructor
      #
      # Parameters::
      # * *nexus_mods* (NexusMods): The NexusMods API instance that the resource can use to query for other resources
      # * *game_domain_name* (String): The game this file belongs to
      # * *mod_id* (Integer): The mod's id
      # * *latest_file_update* (Time): The mod's latest file update
      # * *latest_mod_activity* (Time): The mod's latest activity
      def initialize(
        nexus_mods:,
        game_domain_name:,
        mod_id:,
        latest_file_update:,
        latest_mod_activity:
      )
        super(nexus_mods:)
        @game_domain_name = game_domain_name
        @mod_id = mod_id
        @latest_file_update = latest_file_update
        @latest_mod_activity = latest_mod_activity
      end

      # Equality operator
      #
      # Parameters::
      # * *other* (Object): Other object to compare with
      # Result::
      # * Boolean: Are objects equal?
      def ==(other)
        other.is_a?(ModUpdates) &&
          @game_domain_name == game_domain_name &&
          @mod_id == other.mod_id &&
          @latest_file_update == other.latest_file_update &&
          @latest_mod_activity == other.latest_mod_activity
      end

      # Get associated mod information
      #
      # Result::
      # * Mod: The corresponding mod
      def mod
        @nexus_mods.mod(game_domain_name:, mod_id:)
      end

      # Get associated mod files information
      #
      # Result::
      # * Array<ModFile>: The corresponding mod files
      def mod_files
        @nexus_mods.mod_files(game_domain_name:, mod_id:)
      end

    end

  end

end
