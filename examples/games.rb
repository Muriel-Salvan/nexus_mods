require 'nexus_mods'

games = NexusMods.new(api_key: ENV.fetch('NEXUS_MODS_API_KEY')).games
puts "Found a total of #{games.size} games."
puts 'Here is the top 10 by number of downloads:'
games.sort_by { |game| -game.downloads_count }[0..9].each do |game|
  puts "* #{game.name} (#{game.mods_count} mods, #{game.downloads_count} downloads)"
end
