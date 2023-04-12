require 'fileutils'

describe NexusMods do

  context 'when testing caching' do

    it 'does not cache user queries' do
      expect_validate_user(times: 3)
      nexus_mods.api_limits
      nexus_mods.api_limits
    end

    {
      'games' => {
        expected_api_path: '/v1/games.json',
        mocked_api_json: [
          NexusModsTest::Factories::Games.json_game100,
          NexusModsTest::Factories::Games.json_game101
        ],
        query: proc { |nm| nm.games },
        query_without_cache: proc { |nm| nm.games(clear_cache: true) },
        get_cache_timestamp: proc { |nm| nm.games_cache_timestamp },
        set_cache_timestamp: proc { |nm, ts| nm.set_games_cache_timestamp(cache_timestamp: ts) },
        expiry_cache_param: :games
      },
      'mods' => {
        expected_api_path: '/v1/games/skyrimspecialedition/mods/2014.json',
        mocked_api_json: NexusModsTest::Factories::Mods.json_complete_mod,
        query: proc { |nm| nm.mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014) },
        query_without_cache: proc { |nm| nm.mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014, clear_cache: true) },
        get_cache_timestamp: proc { |nm| nm.mod_cache_timestamp(game_domain_name: 'skyrimspecialedition', mod_id: 2014) },
        set_cache_timestamp: proc { |nm, ts| nm.set_mod_cache_timestamp(game_domain_name: 'skyrimspecialedition', mod_id: 2014, cache_timestamp: ts) },
        expiry_cache_param: :mod
      },
      'mod files' => {
        expected_api_path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
        mocked_api_json: {
          files: [
            NexusModsTest::Factories::ModFiles.json_mod_file2472,
            NexusModsTest::Factories::ModFiles.json_mod_file2487
          ]
        },
        query: proc { |nm| nm.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2014) },
        query_without_cache: proc { |nm| nm.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2014, clear_cache: true) },
        get_cache_timestamp: proc { |nm| nm.mod_files_cache_timestamp(game_domain_name: 'skyrimspecialedition', mod_id: 2014) },
        set_cache_timestamp: proc { |nm, ts| nm.set_mod_files_cache_timestamp(game_domain_name: 'skyrimspecialedition', mod_id: 2014, cache_timestamp: ts) },
        expiry_cache_param: :mod_files
      }
    }.merge(
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
      }.to_h do |since, since_config|
        [
          "mod updates since #{since}",
          {
            expected_api_path: "/v1/games/skyrimspecialedition/mods/updated.json?#{since_config[:expected_url_params]}",
            mocked_api_json: [
              NexusModsTest::Factories::ModUpdates.json_mod_updates2014,
              NexusModsTest::Factories::ModUpdates.json_mod_updates100
            ],
            query: proc { |nm| nm.updated_mods(game_domain_name: 'skyrimspecialedition', since: since_config[:since]) },
            query_without_cache: proc { |nm| nm.updated_mods(game_domain_name: 'skyrimspecialedition', since: since_config[:since], clear_cache: true) },
            get_cache_timestamp: proc { |nm| nm.updated_mods_cache_timestamp(game_domain_name: 'skyrimspecialedition', since: since_config[:since]) },
            set_cache_timestamp: proc { |nm, ts| nm.set_updated_mods_cache_timestamp(game_domain_name: 'skyrimspecialedition', since: since_config[:since], cache_timestamp: ts) }
          }
        ]
      end
    ).each do |resource, resource_config|

      context "when testing #{resource}" do

        it 'caches API queries' do
          expect_validate_user
          expect_http_call_to(
            path: resource_config[:expected_api_path],
            json: resource_config[:mocked_api_json]
          )
          resource = resource_config[:query].call(nexus_mods)
          expect(resource_config[:query].call(nexus_mods)).to eq resource
        end

        it 'does not cache API queries if asked' do
          expect_validate_user
          expect_http_call_to(
            path: resource_config[:expected_api_path],
            json: resource_config[:mocked_api_json],
            times: 2
          )
          resource = resource_config[:query].call(nexus_mods)
          expect(resource_config[:query_without_cache].call(nexus_mods)).to eq resource
        end

        if resource_config[:expiry_cache_param]

          it 'expires API queries cache' do
            expect_validate_user
            expect_http_call_to(
              path: resource_config[:expected_api_path],
              json: resource_config[:mocked_api_json],
              times: 2
            )
            nexus_mods_instance = nexus_mods(api_cache_expiry: { resource_config[:expiry_cache_param] => 1 })
            resource = resource_config[:query].call(nexus_mods_instance)
            sleep 2
            expect(resource_config[:query].call(nexus_mods_instance)).to eq resource
          end

        end

        it 'stores no timestamp of the data stored in the API cache before fetching data' do
          expect_validate_user
          expect(resource_config[:get_cache_timestamp].call(nexus_mods)).to be_nil
        end

        it 'retrieves the timestamp of the data stored in the API cache' do
          expect_validate_user
          expect_http_call_to(
            path: resource_config[:expected_api_path],
            json: resource_config[:mocked_api_json]
          )
          before = Time.now
          resource_config[:query].call(nexus_mods)
          after = Time.now
          expect(resource_config[:get_cache_timestamp].call(nexus_mods)).to be_between(before, after)
        end

        it 'changes manually the timestamp of the data stored in the API cache' do
          expect_validate_user
          expect_http_call_to(
            path: resource_config[:expected_api_path],
            json: resource_config[:mocked_api_json]
          )
          resource_config[:query].call(nexus_mods)
          new_cache_timestamp = Time.parse('2023-01-12 11:22:33 UTC')
          resource_config[:set_cache_timestamp].call(nexus_mods, new_cache_timestamp)
          expect(resource_config[:get_cache_timestamp].call(nexus_mods)).to eq new_cache_timestamp
        end

        it 'retrieves the timestamp of the games data stored in the cache even after cache is used' do
          expect_validate_user
          expect_http_call_to(
            path: resource_config[:expected_api_path],
            json: resource_config[:mocked_api_json]
          )
          before = Time.now
          resource_config[:query].call(nexus_mods)
          after = Time.now
          resource_config[:query].call(nexus_mods)
          expect(resource_config[:get_cache_timestamp].call(nexus_mods)).to be_between(before, after)
        end

        it 'retrieves the timestamp of the games data stored in the cache even after cache is persisted' do
          with_api_cache_file do |api_cache_file|
            expect_validate_user(times: 2)
            expect_http_call_to(
              path: resource_config[:expected_api_path],
              json: resource_config[:mocked_api_json]
            )
            before = Time.now
            resource_config[:query].call(nexus_mods(api_cache_file:))
            after = Time.now
            reset_nexus_mods
            expect(resource_config[:get_cache_timestamp].call(nexus_mods(api_cache_file:))).to be_between(before, after)
          end
        end

        it 'persists the cache timestamp that has been changed manually' do
          with_api_cache_file do |api_cache_file|
            expect_validate_user(times: 2)
            expect_http_call_to(
              path: resource_config[:expected_api_path],
              json: resource_config[:mocked_api_json]
            )
            resource_config[:query].call(nexus_mods(api_cache_file:))
            new_cache_timestamp = Time.parse('2023-01-12 11:22:33 UTC')
            resource_config[:set_cache_timestamp].call(nexus_mods, new_cache_timestamp)
            reset_nexus_mods
            expect(resource_config[:get_cache_timestamp].call(nexus_mods(api_cache_file:))).to eq new_cache_timestamp
          end
        end

        it 'updates the timestamp of the data stored in the API cache by forcing an API query' do
          expect_validate_user
          expect_http_call_to(
            path: resource_config[:expected_api_path],
            json: resource_config[:mocked_api_json],
            times: 2
          )
          resource_config[:query].call(nexus_mods)
          sleep 1
          before = Time.now
          resource_config[:query_without_cache].call(nexus_mods)
          after = Time.now
          expect(resource_config[:get_cache_timestamp].call(nexus_mods)).to be_between(before, after)
        end

        it 'updates the timestamp of the data stored in the API cache by updating manually the cache timestamp' do
          expect_validate_user
          expect_http_call_to(
            path: resource_config[:expected_api_path],
            json: resource_config[:mocked_api_json],
            times: 2
          )
          resource_config[:query].call(nexus_mods)
          resource_config[:set_cache_timestamp].call(nexus_mods, Time.now.utc - 365 * 24 * 60 * 60)
          before = Time.now
          resource_config[:query].call(nexus_mods)
          after = Time.now
          expect(resource_config[:get_cache_timestamp].call(nexus_mods)).to be_between(before, after)
        end

        context 'when testing cache persistence in files' do

          it 'persists API cache in a file' do
            with_api_cache_file do |api_cache_file|
              expect_validate_user
              expect_http_call_to(
                path: resource_config[:expected_api_path],
                json: resource_config[:mocked_api_json]
              )
              resource_config[:query].call(nexus_mods(api_cache_file:))
              expect(File.exist?(api_cache_file)).to be true
              expect(File.size(api_cache_file)).to be > 0
            end
          end

          it 'uses API cache from a file' do
            with_api_cache_file do |api_cache_file|
              expect_validate_user(times: 2)
              expect_http_call_to(
                path: resource_config[:expected_api_path],
                json: resource_config[:mocked_api_json]
              )
              # Generate the cache first
              resource = resource_config[:query].call(nexus_mods(api_cache_file:))
              # Force a new instance of NexusMods API to run
              reset_nexus_mods
              expect(resource_config[:query].call(nexus_mods(api_cache_file:))).to eq resource
            end
          end

          if resource_config[:expiry_cache_param]

            it 'uses API cache from a file, taking expiry time into account' do
              with_api_cache_file do |api_cache_file|
                expect_validate_user(times: 2)
                expect_http_call_to(
                  path: resource_config[:expected_api_path],
                  json: resource_config[:mocked_api_json],
                  times: 2
                )
                # Generate the cache first
                resource = resource_config[:query].call(nexus_mods(api_cache_file:, api_cache_expiry: { resource_config[:expiry_cache_param] => 1 }))
                # Force a new instance of NexusMods API to run
                reset_nexus_mods
                sleep 2
                # As the expiry time is 1 second, then the cache should still be invalidated
                expect(resource_config[:query].call(nexus_mods(api_cache_file:, api_cache_expiry: { resource_config[:expiry_cache_param] => 1 }))).to eq resource
              end
            end

            it 'uses API cache from a file, taking expiry time of the new process into account' do
              with_api_cache_file do |api_cache_file|
                expect_validate_user(times: 2)
                expect_http_call_to(
                  path: resource_config[:expected_api_path],
                  json: resource_config[:mocked_api_json],
                  times: 2
                )
                # Generate the cache first
                resource = resource_config[:query].call(nexus_mods(api_cache_file:, api_cache_expiry: { resource_config[:expiry_cache_param] => 10 }))
                # Force a new instance of NexusMods API to run
                reset_nexus_mods
                sleep 2
                # Even if the expiry time was 10 seconds while fetching the resource,
                # if we decide it has to be 1 second now then it has to be invalidated.
                expect(resource_config[:query].call(nexus_mods(api_cache_file:, api_cache_expiry: { resource_config[:expiry_cache_param] => 1 }))).to eq resource
              end
            end

          end

        end

      end

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
