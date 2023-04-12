require 'nexus_mods/api/resource'

class NexusMods

  module Api

    # Object giving the NexusMods API limits
    class ApiLimits < Resource

      attr_reader(
        *%i[
          daily_limit
          daily_remaining
          daily_reset
          hourly_limit
          hourly_remaining
          hourly_reset
        ]
      )

      # Constructor
      #
      # Parameters::
      # * *nexus_mods* (NexusMods): The NexusMods API instance that the resource can use to query for other resources
      # * *daily_limit* (Integer): The daily limit
      # * *daily_remaining* (Integer): The daily remaining
      # * *daily_reset* (Integer): The daily reset time
      # * *hourly_limit* (Integer): The hourly limit
      # * *hourly_remaining* (Integer): The hourly remaining
      # * *hourly_reset* (Integer): The hourly reset time
      def initialize(
        nexus_mods:,
        daily_limit:,
        daily_remaining:,
        daily_reset:,
        hourly_limit:,
        hourly_remaining:,
        hourly_reset:
      )
        super(nexus_mods:)
        @daily_limit = daily_limit
        @daily_remaining = daily_remaining
        @daily_reset = daily_reset
        @hourly_limit = hourly_limit
        @hourly_remaining = hourly_remaining
        @hourly_reset = hourly_reset
      end

      # Equality operator
      #
      # Parameters::
      # * *other* (Object): Other object to compare with
      # Result::
      # * Boolean: Are objects equal?
      def ==(other)
        other.is_a?(ApiLimits) &&
          @daily_limit == other.daily_limit &&
          @daily_remaining == other.daily_remaining &&
          @daily_reset == other.daily_reset &&
          @hourly_limit == other.hourly_limit &&
          @hourly_remaining == other.hourly_remaining &&
          @hourly_reset == other.hourly_reset
      end

    end

  end

end
