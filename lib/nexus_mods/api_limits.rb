class NexusMods

  # Object giving the NexusMods API limits
  class ApiLimits

    attr_reader(*%i[
      daily_limit
      daily_remaining
      daily_reset
      hourly_limit
      hourly_remaining
      hourly_reset
    ])

    # Constructor
    #
    # Parameters::
    # * *daily_limit* (Integer): The daily limit
    # * *daily_remaining* (Integer): The daily remaining
    # * *daily_reset* (Integer): The daily reset time
    # * *hourly_limit* (Integer): The hourly limit
    # * *hourly_remaining* (Integer): The hourly remaining
    # * *hourly_reset* (Integer): The hourly reset time
    def initialize(
      daily_limit:,
      daily_remaining:,
      daily_reset:,
      hourly_limit:,
      hourly_remaining:,
      hourly_reset:
    )
      @daily_limit = daily_limit
      @daily_remaining = daily_remaining
      @daily_reset = daily_reset
      @hourly_limit = hourly_limit
      @hourly_remaining = hourly_remaining
      @hourly_reset = hourly_reset
    end

  end

end
