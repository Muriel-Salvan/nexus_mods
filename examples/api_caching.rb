require 'nexus_mods'
require 'fileutils'

# Make sure a previous file for caching was not here before
test_api_cache_file = 'nexus_mods_test_api_cache.json'
FileUtils.rm_f test_api_cache_file

nexus_mods = NexusMods.new(
  api_key: ENV.fetch('NEXUS_MODS_API_KEY'),
  api_cache_file: test_api_cache_file
)

initial_remaining = nexus_mods.api_limits.daily_remaining
puts "Before fetching anything, daily API remaining is #{initial_remaining}"

puts 'Fetch the list of games (without using cache)...'
puts "Fetched #{nexus_mods.games.size} games."

puts "After fetching those games, daily API remaining is #{nexus_mods.api_limits.daily_remaining}"

puts 'Now we fetch again the list of games (this should use the cache)...'
puts "Fetched #{nexus_mods.games.size} games."

puts "After fetching those games a second time, daily API remaining is #{nexus_mods.api_limits.daily_remaining}"

puts 'Now we close the current NexusMods instance ad re-instantiate a new one from scratch using the same API cache file'

new_nexus_mods = NexusMods.new(
  api_key: ENV.fetch('NEXUS_MODS_API_KEY'),
  api_cache_file: test_api_cache_file
)

puts "Before fetching anything from the new instance, daily API remaining is #{new_nexus_mods.api_limits.daily_remaining}"

puts 'Now we fetch the list of games from the new instance (this should use the cache that was stored in the file)...'
puts "Fetched #{new_nexus_mods.games.size} games."

puts "After fetching those games from the new instance, daily API remaining is #{new_nexus_mods.api_limits.daily_remaining}"

puts
puts "As a conclusion, we used 2 instances of NexusMods that have fetched games 3 times, and it consumed #{initial_remaining - new_nexus_mods.api_limits.daily_remaining} real API call."
