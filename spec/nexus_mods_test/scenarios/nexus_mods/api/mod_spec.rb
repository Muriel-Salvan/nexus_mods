describe NexusMods::Api::Mod do

  context 'when testing mods' do

    before do
      expect_validate_user
    end

    context 'when accessing a partial mod' do

      before do
        expect_http_call_to(
          path: '/v1/games/skyrimspecialedition/mods/2014.json',
          json: json_partial_mod
        )
      end

      it 'returns the mod information' do
        expect_mod_to_be_partial(nexus_mods.mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014))
      end

    end

    context 'when accessing a complete mod' do

      before do
        expect_http_call_to(
          path: '/v1/games/skyrimspecialedition/mods/2014.json',
          json: json_complete_mod
        )
      end

      it 'returns the mod information' do
        expect_mod_to_be_complete(nexus_mods.mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014))
      end

      it 'returns the default mod information' do
        expect_mod_to_be_complete(nexus_mods(mod_id: 2014).mod(game_domain_name: 'skyrimspecialedition'))
      end

      it 'returns mod information for the default game' do
        expect_mod_to_be_complete(nexus_mods(game_domain_name: 'skyrimspecialedition').mod(mod_id: 2014))
      end

      it 'returns mod information for the default game set using accessor' do
        nexus_mods.game_domain_name = 'skyrimspecialedition'
        expect_mod_to_be_complete(nexus_mods.mod(mod_id: 2014))
      end

      it 'returns mod information for the default game and mod' do
        expect_mod_to_be_complete(nexus_mods(game_domain_name: 'skyrimspecialedition', mod_id: 2014).mod)
      end

      it 'returns mod information for the default game and mod set using accessor' do
        nexus_mods.mod_id = 2014
        expect_mod_to_be_complete(nexus_mods.mod(game_domain_name: 'skyrimspecialedition'))
      end

      it 'compares objects for equality' do
        mod1 = nexus_mods.mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014)
        mod2 = nexus_mods.mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014)
        expect(mod1.object_id).not_to eq mod2.object_id
        expect(mod1).to eq mod2
      end

    end

    context 'when checking cache data freshness' do

      it 'returns that a mod never retrieved is not up-to-date' do
        expect(nexus_mods.mod_cache_up_to_date?(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to be false
      end

      context 'when retrieving a mod previously' do

        before do
          expect_http_call_to(
            path: '/v1/games/skyrimspecialedition/mods/2014.json',
            json: json_complete_mod
          )
          nexus_mods.mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014)
        end

        context 'when retrieved 40 days ago' do

          let(:forty_days_ago) { Time.now - (40 * 24 * 60 * 60) }

          before do
            nexus_mods.set_mod_cache_timestamp(cache_timestamp: forty_days_ago, game_domain_name: 'skyrimspecialedition', mod_id: 2014)
          end

          it 'returns that the mod is not up-to-date' do
            expect(nexus_mods.mod_cache_up_to_date?(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to be false
            expect(nexus_mods.mod_cache_timestamp(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to eq forty_days_ago
          end

        end

        context 'when retrieved 2 days ago' do

          let(:two_days_ago) { Time.now - (2 * 24 * 60 * 60) }

          before do
            nexus_mods.set_mod_cache_timestamp(cache_timestamp: two_days_ago, game_domain_name: 'skyrimspecialedition', mod_id: 2014)
          end

          it 'returns that the mod is up-to-date after checking updated mods and not finding it, and updates its cache timestamp to the update time' do
            expect_http_call_to(
              path: '/v1/games/skyrimspecialedition/mods/updated.json?period=1m',
              json: []
            )
            expect(nexus_mods.mod_cache_up_to_date?(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to be true
            expect(nexus_mods.mod_cache_timestamp(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to eq(
              nexus_mods.updated_mods_cache_timestamp(game_domain_name: 'skyrimspecialedition', since: :one_month)
            )
          end

          it 'returns that the mod is up-to-date after checking updated mods and finding that cache is more recent, and updates its cache timestamp to the update time' do
            expect_http_call_to(
              path: '/v1/games/skyrimspecialedition/mods/updated.json?period=1m',
              json: [
                {
                  'mod_id' => 2014,
                  # Mock that mod was updated 3 days ago
                  'latest_file_update' => 1,
                  'latest_mod_activity' => Integer((Time.now - (3 * 24 * 60 * 60)).strftime('%s'))
                }
              ]
            )
            expect(nexus_mods.mod_cache_up_to_date?(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to be true
            expect(nexus_mods.mod_cache_timestamp(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to eq(
              nexus_mods.updated_mods_cache_timestamp(game_domain_name: 'skyrimspecialedition', since: :one_month)
            )
          end

          it 'returns that the mod is not up-to-date after checking updated mods and finding that cache is less recent' do
            expect_http_call_to(
              path: '/v1/games/skyrimspecialedition/mods/updated.json?period=1m',
              json: [
                {
                  'mod_id' => 2014,
                  # Mock that mod was updated yesterday
                  'latest_file_update' => 1,
                  'latest_mod_activity' => Integer((Time.now - (24 * 60 * 60)).strftime('%s'))
                }
              ]
            )
            expect(nexus_mods.mod_cache_up_to_date?(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to be false
            expect(nexus_mods.mod_cache_timestamp(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to eq two_days_ago
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
                  'latest_file_update' => 1,
                  'latest_mod_activity' => Integer((Time.now - (3 * 24 * 60 * 60)).strftime('%s'))
                }
              ]
            )
            nexus_mods.updated_mods(game_domain_name: 'skyrimspecialedition', since: :one_month)
            nexus_mods.set_mod_cache_timestamp(cache_timestamp: three_minutes_ago, game_domain_name: 'skyrimspecialedition', mod_id: 2014)
            nexus_mods.set_updated_mods_cache_timestamp(cache_timestamp: four_minutes_ago, game_domain_name: 'skyrimspecialedition', since: :one_month)
          end

          it 'returns that the mod is up-to-date but doesn\'t change its mod cache timestamp' do
            expect(nexus_mods.mod_cache_up_to_date?(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to be true
            expect(nexus_mods.mod_cache_timestamp(game_domain_name: 'skyrimspecialedition', mod_id: 2014)).to eq three_minutes_ago
            expect(nexus_mods.updated_mods_cache_timestamp(game_domain_name: 'skyrimspecialedition', since: :one_month)).to eq four_minutes_ago
          end

        end

      end

    end

    context 'when checking for updates' do

      before do
        nexus_mods(game_domain_name: 'skyrimspecialedition', mod_id: 2014)
      end

      it 'does not check for updates if mod has not been retrieved before' do
        expect_http_call_to(
          path: '/v1/games/skyrimspecialedition/mods/2014.json',
          json: json_complete_mod
        )
        expect_mod_to_be_complete(nexus_mods.mod(check_updates: true))
      end

      it 'does not check for updates if mod has been retrieved more than 1 month ago, and re-query the mod' do
        expect_http_call_to(
          path: '/v1/games/skyrimspecialedition/mods/2014.json',
          json: json_complete_mod,
          times: 2
        )
        nexus_mods.mod
        nexus_mods.set_mod_cache_timestamp(cache_timestamp: Time.now - (40 * 24 * 60 * 60), game_domain_name: 'skyrimspecialedition', mod_id: 2014)
        expect_mod_to_be_complete(nexus_mods.mod(check_updates: true))
      end

      it 'checks for updates when mod has been retrieved less than 1 month ago and does nothing if its date is less recent than the cache' do
        expect_http_call_to(
          path: '/v1/games/skyrimspecialedition/mods/2014.json',
          json: json_complete_mod
        )
        expect_http_call_to(
          path: '/v1/games/skyrimspecialedition/mods/updated.json?period=1m',
          json: [
            {
              'mod_id' => 2014,
              # Mock that mod was updated 25 days ago
              'latest_file_update' => 1,
              'latest_mod_activity' => Integer((Time.now - (25 * 24 * 60 * 60)).strftime('%s'))
            }
          ]
        )
        nexus_mods.mod
        nexus_mods.set_mod_cache_timestamp(cache_timestamp: Time.now - (20 * 24 * 60 * 60), game_domain_name: 'skyrimspecialedition', mod_id: 2014)
        expect_mod_to_be_complete(nexus_mods.mod(check_updates: true))
      end

      it 'checks for updates when mod has been retrieved less than 1 month ago and re-query the mod if its date is more recent than the cache' do
        expect_http_call_to(
          path: '/v1/games/skyrimspecialedition/mods/2014.json',
          json: json_complete_mod,
          times: 2
        )
        expect_http_call_to(
          path: '/v1/games/skyrimspecialedition/mods/updated.json?period=1m',
          json: [
            {
              'mod_id' => 2014,
              # Mock that mod was updated 15 days ago
              'latest_file_update' => 1,
              'latest_mod_activity' => Integer((Time.now - (15 * 24 * 60 * 60)).strftime('%s'))
            }
          ]
        )
        nexus_mods.mod
        nexus_mods.set_mod_cache_timestamp(cache_timestamp: Time.now - (20 * 24 * 60 * 60), game_domain_name: 'skyrimspecialedition', mod_id: 2014)
        expect_mod_to_be_complete(nexus_mods.mod(check_updates: true))
      end

    end

  end

end
