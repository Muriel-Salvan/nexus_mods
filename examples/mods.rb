require 'nexus_mods'

nexus_mods = NexusMods.new(
  api_key: ENV.fetch('NEXUS_MODS_API_KEY'),
  game_domain_name: 'skyrimspecialedition'
)
some_mod_ids = [
  266,
  2_347,
  17_230,
  42_521
]
puts 'Here are some details about a few mods for Skyrim Special Edition:'
puts
some_mod_ids.each do |mod_id|
  mod = nexus_mods.mod(mod_id:)
  mod_files = nexus_mods.mod_files(mod_id:)
  puts <<~EO_OUTPUT
    ===== #{mod.name} (v#{mod.version}) by #{mod.uploader.name} (#{mod.downloads_count} downloads)
    #{mod.summary}
    * Last 5 files: #{mod_files.reverse[0..4].map(&:file_name).join(', ')}

  EO_OUTPUT
end
