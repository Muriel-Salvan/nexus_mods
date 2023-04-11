class NexusMods

  module Api

    # A NexusMods mod updates.
    class ModUpdates

      attr_reader(
        *%i[
          mod_id
          latest_file_update
          latest_mod_activity
        ]
      )

      # Constructor
      #
      # Parameters::
      # * *mod_id* (Integer): The mod's id
      # * *latest_file_update* (Time): The mod's latest file update
      # * *latest_mod_activity* (Time): The mod's latest activity
      def initialize(
        mod_id:,
        latest_file_update:,
        latest_mod_activity:
      )
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
          @mod_id == other.mod_id &&
          @latest_file_update == other.latest_file_update &&
          @latest_mod_activity == other.latest_mod_activity
      end

    end

  end

end
