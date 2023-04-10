require 'nexus_mods'

puts 'Example of fetching a mod with log debug activated, and without using the cache (so that we always see the query):'
puts
NexusMods.new(
  api_key: ENV.fetch('NEXUS_MODS_API_KEY'),
  log_level: :debug,
  game_domain_name: 'skyrimspecialedition',
  mod_id: 42_521
).mod(clear_cache: true)
