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
      expect(nexus_mods.games).to eq games
    end

    it 'does not cache games queries if asked' do
      expect_validate_user
      expect_http_call_to(
        path: '/v1/games.json',
        json: [
          json_game100,
          json_game101
        ],
        times: 2
      )
      games = nexus_mods.games
      expect(nexus_mods.games(clear_cache: true)).to eq games
    end

    it 'caches mod queries' do
      expect_validate_user
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014.json',
        json: json_complete_mod
      )
      mod = nexus_mods.mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014)
      expect(nexus_mods.mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to eq mod
    end

    it 'does not cache mod queries if asked' do
      expect_validate_user
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014.json',
        json: json_complete_mod,
        times: 2
      )
      mod = nexus_mods.mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014)
      expect(nexus_mods.mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014, clear_cache: true)).to eq mod
    end

    it 'caches mod files queries' do
      expect_validate_user
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
        json: { files: [json_mod_file2472, json_mod_file2487] }
      )
      mod_files = nexus_mods.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2014)
      expect(nexus_mods.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to eq mod_files
    end

    it 'does not cache mod files queries if asked' do
      expect_validate_user
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
        json: { files: [json_mod_file2472, json_mod_file2487] },
        times: 2
      )
      mod_files = nexus_mods.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2014)
      expect(nexus_mods.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2014, clear_cache: true)).to eq mod_files
    end

    {
      'last day' => {
        since: :one_day,
        expected_url_params: 'period=1d'
      },
      'last week' => {
        since: :one_week,
        expected_url_params: 'period=1w'
      },
      'last month' => {
        since: :one_month,
        expected_url_params: 'period=1m'
      }
    }.each do |since, since_config|

      context "when testing updated months since #{since}" do

        it 'caches mod updates queries' do
          expect_validate_user
          expect_http_call_to(
            path: "/v1/games/skyrimspecialedition/mods/updated.json?#{since_config[:expected_url_params]}",
            json: [
              json_mod_updates2014,
              json_mod_updates100
            ]
          )
          mod_updates = nexus_mods.updated_mods(game_domain_name: 'skyrimspecialedition', since: since_config[:since])
          expect(nexus_mods.updated_mods(game_domain_name: 'skyrimspecialedition', since: since_config[:since])).to eq mod_updates
        end

        it 'does not cache mod updates queries if asked' do
          expect_validate_user
          expect_http_call_to(
            path: "/v1/games/skyrimspecialedition/mods/updated.json?#{since_config[:expected_url_params]}",
            json: [
              json_mod_updates2014,
              json_mod_updates100
            ],
            times: 2
          )
          mod_updates = nexus_mods.updated_mods(game_domain_name: 'skyrimspecialedition', since: since_config[:since])
          expect(nexus_mods.updated_mods(game_domain_name: 'skyrimspecialedition', since: since_config[:since], clear_cache: true)).to eq mod_updates
        end

      end

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
      expect(nexus_mods_instance.games).to eq games
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
      expect(nexus_mods_instance.mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to eq mod
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
      expect(nexus_mods_instance.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to eq mod_files
    end

    it 'only clears the cache of the wanted resource' do
      expect_validate_user
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
        json: { files: [json_mod_file2472] },
        times: 2
      )
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2015/files.json',
        json: { files: [json_mod_file2487] }
      )
      mod_files20141 = nexus_mods.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2014)
      mod_files20151 = nexus_mods.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2015)
      mod_files20142 = nexus_mods.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2014, clear_cache: true)
      mod_files20152 = nexus_mods.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2015)
      expect(mod_files20141).to eq mod_files20142
      expect(mod_files20151).to eq mod_files20152
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
          reset_nexus_mods
          expect(nexus_mods(api_cache_file:).games).to eq games
        end
      end

      it 'uses API cache from a file, taking expiry time into account' do
        with_api_cache_file do |api_cache_file|
          expect_validate_user(times: 2)
          expect_http_call_to(
            path: '/v1/games.json',
            json: [
              json_game100,
              json_game101
            ],
            times: 2
          )
          # Generate the cache first
          games = nexus_mods(api_cache_file:, api_cache_expiry: { games: 1 }).games
          # Force a new instance of NexusMods API to run
          reset_nexus_mods
          sleep 2
          # As the expiry time is 1 second, then the cache should still be invalidated
          expect(nexus_mods(api_cache_file:, api_cache_expiry: { games: 1 }).games).to eq games
        end
      end

      it 'uses API cache from a file, taking expiry time of the new process into account' do
        with_api_cache_file do |api_cache_file|
          expect_validate_user(times: 2)
          expect_http_call_to(
            path: '/v1/games.json',
            json: [
              json_game100,
              json_game101
            ],
            times: 2
          )
          # Generate the cache first
          games = nexus_mods(api_cache_file:, api_cache_expiry: { games: 10 }).games
          # Force a new instance of NexusMods API to run
          reset_nexus_mods
          sleep 2
          # Even if the expiry time was 10 seconds while fetching the resource,
          # if we decide it has to be 1 second now then it has to be invalidated.
          expect(nexus_mods(api_cache_file:, api_cache_expiry: { games: 1 }).games).to eq games
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
          reset_nexus_mods
          # Complete the cache with a mod
          expect_http_call_to(
            path: '/v1/games/skyrimspecialedition/mods/2014.json',
            json: json_complete_mod
          )
          mod = nexus_mods(api_cache_file:).mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014)
          # Force a new instance of NexusMods API to run
          reset_nexus_mods
          # Check that both API calls were cached correctly
          nexus_mods_instance = nexus_mods(api_cache_file:)
          expect(nexus_mods_instance.games).to eq games
          expect(nexus_mods_instance.mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to eq mod
        end
      end

      it 'clears the cache of a wanted resource in the API cache file as well' do
        with_api_cache_file do |api_cache_file|
          expect_validate_user(times: 3)
          # Generate the cache first for 2 mod files queries
          expect_http_call_to(
            path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
            json: { files: [json_mod_file2472] },
            times: 2
          )
          expect_http_call_to(
            path: '/v1/games/skyrimspecialedition/mods/2015/files.json',
            json: { files: [json_mod_file2487] }
          )
          nexus_mods_instance1 = nexus_mods(api_cache_file:)
          mod_files20141 = nexus_mods_instance1.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2014)
          mod_files20151 = nexus_mods_instance1.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2015)
          # Force a new instance of NexusMods API to run
          reset_nexus_mods
          # Clear the cache of the first API query
          nexus_mods_instance2 = nexus_mods(api_cache_file:)
          mod_files20142 = nexus_mods_instance2.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2014, clear_cache: true)
          mod_files20152 = nexus_mods_instance2.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2015)
          # Force a new instance of NexusMods API to run
          reset_nexus_mods
          # Get again the data, it should have been in the cache already
          nexus_mods_instance3 = nexus_mods(api_cache_file:)
          mod_files20143 = nexus_mods_instance3.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2014)
          mod_files20153 = nexus_mods_instance3.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2015)
          expect(mod_files20141).to eq mod_files20142
          expect(mod_files20141).to eq mod_files20143
          expect(mod_files20151).to eq mod_files20152
          expect(mod_files20151).to eq mod_files20153
        end
      end

    end

  end

end
