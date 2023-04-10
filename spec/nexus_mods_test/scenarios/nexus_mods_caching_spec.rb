describe NexusMods do

  context 'when testing caching' do

    it 'does not cache user queries' do
      expect_validate_user(times: 3)
      nexus_mods.api_limits
      nexus_mods.api_limits
    end

    it 'caches games queries' do
      expect_validate_user
      expect_http_call_to(
        path: '/v1/games.json',
        json: [
          json_game100,
          json_game101
        ]
      )
      games = nexus_mods.games
      expect(nexus_mods.games).to eq(games)
    end

    it 'caches mod queries' do
      expect_validate_user
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014.json',
        json: json_complete_mod
      )
      mod = nexus_mods.mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014)
      expect(nexus_mods.mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to eq(mod)
    end

    it 'caches mod files queries' do
      expect_validate_user
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
        json: { files: [json_mod_file2472, json_mod_file2487] }
      )
      mod_files = nexus_mods.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2014)
      expect(nexus_mods.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to eq(mod_files)
    end

    it 'expires games queries cache' do
      expect_validate_user
      expect_http_call_to(
        path: '/v1/games.json',
        json: [
          json_game100,
          json_game101
        ],
        times: 2
      )
      nexus_mods_instance = nexus_mods(api_cache_expiry: { games: 1 })
      games = nexus_mods_instance.games
      sleep 2
      expect(nexus_mods_instance.games).to eq(games)
    end

    it 'expires mod queries cache' do
      expect_validate_user
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014.json',
        json: json_complete_mod,
        times: 2
      )
      nexus_mods_instance = nexus_mods(api_cache_expiry: { mod: 1 })
      mod = nexus_mods_instance.mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014)
      sleep 2
      expect(nexus_mods_instance.mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to eq(mod)
    end

    it 'expires mod files queries cache' do
      expect_validate_user
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
        json: { files: [json_mod_file2472, json_mod_file2487] },
        times: 2
      )
      nexus_mods_instance = nexus_mods(api_cache_expiry: { mod_files: 1 })
      mod_files = nexus_mods_instance.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2014)
      sleep 2
      expect(nexus_mods_instance.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to eq(mod_files)
    end

  end

end
