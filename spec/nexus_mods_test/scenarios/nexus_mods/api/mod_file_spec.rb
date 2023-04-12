describe NexusMods::Api::ModFile do

  context 'when testing mod files' do

    before do
      expect_validate_user
    end

    # Example of JSON object returned by the API for a mod files list
    let(:json_example_mod_files) do
      [
        json_mod_file2472,
        json_mod_file2487
      ]
    end

    # Expect a mod's files to be the example ones
    #
    # Parameters::
    # * *mod_files* (Array<NexusMods::Api::File>): List of files to validate
    def expect_mod_files_to_be_example(mod_files)
      expect(mod_files.size).to eq 2
      sorted_mod_files = mod_files.sort_by(&:id)
      expect_mod_file_to_be2472(sorted_mod_files.first)
      expect_mod_file_to_be2487(sorted_mod_files[1])
    end

    context 'when testing a mod with 2 files' do

      before do
        expect_http_call_to(
          path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
          json: { 'files' => json_example_mod_files }
        )
      end

      it 'returns a mod files list' do
        expect_mod_files_to_be_example(nexus_mods.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2014))
      end

      it 'returns the default mod files list' do
        expect_mod_files_to_be_example(nexus_mods(mod_id: 2014).mod_files(game_domain_name: 'skyrimspecialedition'))
      end

      it 'returns mod files list for the default game' do
        expect_mod_files_to_be_example(nexus_mods(game_domain_name: 'skyrimspecialedition').mod_files(mod_id: 2014))
      end

      it 'returns mod files list for the default game set using accessor' do
        nexus_mods.game_domain_name = 'skyrimspecialedition'
        expect_mod_files_to_be_example(nexus_mods.mod_files(mod_id: 2014))
      end

      it 'returns mod files list for the default game and mod' do
        expect_mod_files_to_be_example(nexus_mods(game_domain_name: 'skyrimspecialedition', mod_id: 2014).mod_files)
      end

      it 'returns mod files list for the default game and mod using accessor' do
        nexus_mods.mod_id = 2014
        expect_mod_files_to_be_example(nexus_mods.mod_files(game_domain_name: 'skyrimspecialedition'))
      end

    end

    it 'compares objects for equality' do
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
        json: { 'files' => [json_mod_file2472] }
      )
      mod_file1 = nexus_mods(game_domain_name: 'skyrimspecialedition', mod_id: 2014).mod_files.first
      mod_file2 = nexus_mods(game_domain_name: 'skyrimspecialedition', mod_id: 2014).mod_files.first
      expect(mod_file1.object_id).not_to eq mod_file2.object_id
      expect(mod_file1).to eq mod_file2
    end

    {
      main: 1,
      patch: 2,
      optional: 3,
      old: 4,
      miscellaneous: 5,
      deleted: 6,
      archived: 7,
      unknown: 100
    }.each do |category, category_id|
      it "accepts mod files having category #{category}" do
        expect_http_call_to(
          path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
          json: {
            'files' => [
              {
                'id' => [
                  2472,
                  1704
                ],
                'uid' => 7_318_624_274_856,
                'file_id' => 2472,
                'name' => 'ApachiiSkyHair_v_1_6_Full',
                'version' => '1.6.Full',
                'category_id' => category_id,
                'category_name' => 'OLD_VERSION',
                'is_primary' => false,
                'file_name' => 'ApachiiSkyHair_v_1_6_Full-2014-1-6-Full.7z',
                'uploaded_timestamp' => 1_477_967_645,
                'uploaded_time' => '2016-11-01T02:34:05.000+00:00',
                'mod_version' => '1.6.Full',
                'external_virus_scan_url' => 'https://www.virustotal.com/file/3dcc96dce0b846ea643d626c48bd6ad08752da8232f3d29be644d36e1fd627cf/analysis/1477978674/',
                'description' => '[b][color=orange] NOT optimized meshes. Standalone. Adds 42 new hairstyles for females, 21 hair for males and 5 hairs for Female Khajiit- 2 hairs for Male Khajiit[/color][/b]  ',
                'size' => 304_347,
                'size_kb' => 304_347,
                'size_in_bytes' => 309_251_227,
                'changelog_html' => nil,
                'content_preview_link' => 'https://file-metadata.nexusmods.com/file/nexus-files-meta/1704/2014/ApachiiSkyHair_v_1_6_Full-2014-1-6-Full.7z.json'
              }
            ]
          }
        )
        mod_file = nexus_mods(game_domain_name: 'skyrimspecialedition', mod_id: 2014).mod_files.first
        expect(mod_file.category).to eq category
        expect(mod_file.category_id).to eq category_id
      end
    end

    context 'when checking cache data freshness' do

      it 'returns that mod files never retrieved are not up-to-date' do
        expect(nexus_mods.mod_files_cache_up_to_date?(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to be false
      end

      context 'when retrieving mod files previously' do

        before do
          expect_http_call_to(
            path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
            json: { 'files' => [json_mod_file2472] }
          )
          nexus_mods.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2014)
        end

        context 'when retrieved 40 days ago' do

          let(:forty_days_ago) { Time.now - (40 * 24 * 60 * 60) }

          before do
            nexus_mods.set_mod_files_cache_timestamp(cache_timestamp: forty_days_ago, game_domain_name: 'skyrimspecialedition', mod_id: 2014)
          end

          it 'returns that mod files are not up-to-date' do
            expect(nexus_mods.mod_files_cache_up_to_date?(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to be false
            expect(nexus_mods.mod_files_cache_timestamp(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to eq forty_days_ago
          end

        end

        context 'when retrieved 2 days ago' do

          let(:two_days_ago) { Time.now - (2 * 24 * 60 * 60) }

          before do
            nexus_mods.set_mod_files_cache_timestamp(cache_timestamp: two_days_ago, game_domain_name: 'skyrimspecialedition', mod_id: 2014)
          end

          it 'returns that mod files are up-to-date after checking updated mods and not finding it, and updates its cache timestamp to the update time' do
            expect_http_call_to(
              path: '/v1/games/skyrimspecialedition/mods/updated.json?period=1m',
              json: []
            )
            expect(nexus_mods.mod_files_cache_up_to_date?(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to be true
            expect(nexus_mods.mod_files_cache_timestamp(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to eq(
              nexus_mods.updated_mods_cache_timestamp(game_domain_name: 'skyrimspecialedition', since: :one_month)
            )
          end

          it 'returns that mod files are up-to-date after checking updated mods and finding that cache is more recent, and updates its cache timestamp to the update time' do
            expect_http_call_to(
              path: '/v1/games/skyrimspecialedition/mods/updated.json?period=1m',
              json: [
                {
                  'mod_id' => 2014,
                  # Mock that mod was updated 3 days ago
                  'latest_file_update' => Integer((Time.now - (3 * 24 * 60 * 60)).strftime('%s')),
                  'latest_mod_activity' => 1
                }
              ]
            )
            expect(nexus_mods.mod_files_cache_up_to_date?(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to be true
            expect(nexus_mods.mod_files_cache_timestamp(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to eq(
              nexus_mods.updated_mods_cache_timestamp(game_domain_name: 'skyrimspecialedition', since: :one_month)
            )
          end

          it 'returns that mod files are not up-to-date after checking updated mods and finding that cache is less recent' do
            expect_http_call_to(
              path: '/v1/games/skyrimspecialedition/mods/updated.json?period=1m',
              json: [
                {
                  'mod_id' => 2014,
                  # Mock that mod was updated yesterday
                  'latest_file_update' => Integer((Time.now - (24 * 60 * 60)).strftime('%s')),
                  'latest_mod_activity' => 1
                }
              ]
            )
            expect(nexus_mods.mod_files_cache_up_to_date?(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to be false
            expect(nexus_mods.mod_files_cache_timestamp(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to eq two_days_ago
          end

        end

        context 'when retrieved 3 minutes ago with an updated mods query 4 minutes ago in the cache' do

          let(:three_minutes_ago) { Time.now - (3 * 60) }
          let(:four_minutes_ago) { Time.now - (4 * 60) }

          before do
            expect_http_call_to(
              path: '/v1/games/skyrimspecialedition/mods/updated.json?period=1m',
              json: [
                {
                  'mod_id' => 2014,
                  # Mock that mod was updated 3 days ago
                  'latest_file_update' => Integer((Time.now - (3 * 24 * 60 * 60)).strftime('%s')),
                  'latest_mod_activity' => 1
                }
              ]
            )
            nexus_mods.updated_mods(game_domain_name: 'skyrimspecialedition', since: :one_month)
            nexus_mods.set_mod_files_cache_timestamp(cache_timestamp: three_minutes_ago, game_domain_name: 'skyrimspecialedition', mod_id: 2014)
            nexus_mods.set_updated_mods_cache_timestamp(cache_timestamp: four_minutes_ago, game_domain_name: 'skyrimspecialedition', since: :one_month)
          end

          it 'returns that mod files are up-to-date but doesn\'t change its mod cache timestamp' do
            expect(nexus_mods.mod_files_cache_up_to_date?(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to be true
            expect(nexus_mods.mod_files_cache_timestamp(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to eq three_minutes_ago
            expect(nexus_mods.updated_mods_cache_timestamp(game_domain_name: 'skyrimspecialedition', since: :one_month)).to eq four_minutes_ago
          end

        end

      end

    end

    context 'when checking for updates' do

      before do
        nexus_mods(game_domain_name: 'skyrimspecialedition', mod_id: 2014)
      end

      it 'does not check for updates if mod files have not been retrieved before' do
        expect_http_call_to(
          path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
          json: { 'files' => [json_mod_file2472] }
        )
        expect_mod_file_to_be2472(nexus_mods.mod_files(check_updates: true).first)
      end

      it 'does not check for updates if mod files have been retrieved more than 1 month ago, and re-query the mod' do
        expect_http_call_to(
          path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
          json: { 'files' => [json_mod_file2472] },
          times: 2
        )
        nexus_mods.mod_files
        nexus_mods.set_mod_files_cache_timestamp(cache_timestamp: Time.now - (40 * 24 * 60 * 60), game_domain_name: 'skyrimspecialedition', mod_id: 2014)
        expect_mod_file_to_be2472(nexus_mods.mod_files(check_updates: true).first)
      end

      it 'checks for updates when mod has been retrieved less than 1 month ago and does nothing if its date is less recent than the cache' do
        expect_http_call_to(
          path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
          json: { 'files' => [json_mod_file2472] }
        )
        expect_http_call_to(
          path: '/v1/games/skyrimspecialedition/mods/updated.json?period=1m',
          json: [
            {
              'mod_id' => 2014,
              # Mock that mod was updated 25 days ago
              'latest_file_update' => Integer((Time.now - (25 * 24 * 60 * 60)).strftime('%s')),
              'latest_mod_activity' => 1
            }
          ]
        )
        nexus_mods.mod_files
        nexus_mods.set_mod_files_cache_timestamp(cache_timestamp: Time.now - (20 * 24 * 60 * 60), game_domain_name: 'skyrimspecialedition', mod_id: 2014)
        expect_mod_file_to_be2472(nexus_mods.mod_files(check_updates: true).first)
      end

      it 'checks for updates when mod has been retrieved less than 1 month ago and re-query the mod if its date is more recent than the cache' do
        expect_http_call_to(
          path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
          json: { 'files' => [json_mod_file2472] },
          times: 2
        )
        expect_http_call_to(
          path: '/v1/games/skyrimspecialedition/mods/updated.json?period=1m',
          json: [
            {
              'mod_id' => 2014,
              # Mock that mod was updated 15 days ago
              'latest_file_update' => Integer((Time.now - (15 * 24 * 60 * 60)).strftime('%s')),
              'latest_mod_activity' => 1
            }
          ]
        )
        nexus_mods.mod_files
        nexus_mods.set_mod_files_cache_timestamp(cache_timestamp: Time.now - (20 * 24 * 60 * 60), game_domain_name: 'skyrimspecialedition', mod_id: 2014)
        expect_mod_file_to_be2472(nexus_mods.mod_files(check_updates: true).first)
      end

    end

  end

end
