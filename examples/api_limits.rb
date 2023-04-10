require 'nexus_mods'

api_limits = NexusMods.new(api_key: ENV.fetch('NEXUS_MODS_API_KEY')).api_limits
puts <<~EO_OUTPUT
  API limits:
    daily_limit: #{api_limits.daily_limit}
    daily_remaining: #{api_limits.daily_remaining}
    daily_reset: #{api_limits.daily_reset}
    hourly_limit: #{api_limits.hourly_limit}
    hourly_remaining: #{api_limits.hourly_remaining}
    hourly_reset: #{api_limits.hourly_reset}
EO_OUTPUT
