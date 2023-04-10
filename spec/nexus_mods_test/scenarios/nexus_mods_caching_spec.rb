require 'fileutils'

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

    context 'with file persistence' do

      it 'persists API cache in a file' do
        with_api_cache_file do |api_cache_file|
          expect_validate_user
          expect_http_call_to(
            path: '/v1/games.json',
            json: [
              json_game100,
              json_game101
            ]
          )
          nexus_mods(api_cache_file:).games
          expect(File.exist?(api_cache_file)).to be true
          expect(File.size(api_cache_file)).to be > 0
        end
      end

      it 'uses API cache from a file' do
        with_api_cache_file do |api_cache_file|
          expect_validate_user(times: 2)
          expect_http_call_to(
            path: '/v1/games.json',
            json: [
              json_game100,
              json_game101
            ]
          )
          # Generate the cache first
          games = nexus_mods(api_cache_file:).games
          # Force a new instance of NexusMods API to run
          @nexus_mods = nil
          expect(nexus_mods(api_cache_file:).games).to eq games
        end
      end

      it 'completes the API cache from a file' do
        with_api_cache_file do |api_cache_file|
          expect_validate_user(times: 3)
          # Generate the cache first for games only
          expect_http_call_to(
            path: '/v1/games.json',
            json: [
              json_game100,
              json_game101
            ]
          )
          games = nexus_mods(api_cache_file:).games
          # Force a new instance of NexusMods API to run
          @nexus_mods = nil
          # Complete the cache with a mod
          expect_http_call_to(
            path: '/v1/games/skyrimspecialedition/mods/2014.json',
            json: json_complete_mod
          )
          mod = nexus_mods(api_cache_file:).mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014)
          # Force a new instance of NexusMods API to run
          @nexus_mods = nil
          # Check that both API calls were cached correctly
          nexus_mods_instance = nexus_mods(api_cache_file:)
          expect(nexus_mods_instance.games).to eq games
          expect(nexus_mods_instance.mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to eq mod
        end
      end

    end

  end

end
