describe NexusMods::Api::ModUpdates do

  context 'when testing mod updates' do

    before do
      expect_validate_user
    end

    # Expect the given array of mod updates to be the ones of examples (for mods 100 and 2014)
    #
    # Parameters::
    # * *mod_updates* (Array<NexusMods::Api::ModUpdates>): The list of mod updates to validate
    def expect_mod_updates_to_be_example(mod_updates)
      sorted_mod_updates = mod_updates.sort_by(&:mod_id)
      expect_mod_file_to_be100(sorted_mod_updates.first)
      expect_mod_file_to_be2014(sorted_mod_updates[1])
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

        it 'returns updated mods' do
          expect_http_call_to(
            path: "/v1/games/skyrimspecialedition/mods/updated.json?#{since_config[:expected_url_params]}",
            json: [
              json_mod_updates2014,
              json_mod_updates100
            ]
          )
          expect_mod_updates_to_be_example(nexus_mods.updated_mods(game_domain_name: 'skyrimspecialedition', since: since_config[:since]))
        end

        it 'returns updated mods information for the default game' do
          expect_http_call_to(
            path: "/v1/games/skyrimspecialedition/mods/updated.json?#{since_config[:expected_url_params]}",
            json: [
              json_mod_updates2014,
              json_mod_updates100
            ]
          )
          expect_mod_updates_to_be_example(nexus_mods(game_domain_name: 'skyrimspecialedition').updated_mods(since: since_config[:since]))
        end

        it 'returns updated mods information for the default game set using accessor' do
          expect_http_call_to(
            path: "/v1/games/skyrimspecialedition/mods/updated.json?#{since_config[:expected_url_params]}",
            json: [
              json_mod_updates2014,
              json_mod_updates100
            ]
          )
          nexus_mods.game_domain_name = 'skyrimspecialedition'
          expect_mod_updates_to_be_example(nexus_mods.updated_mods(since: since_config[:since]))
        end

        it 'compares objects for equality' do
          expect_http_call_to(
            path: "/v1/games/skyrimspecialedition/mods/updated.json?#{since_config[:expected_url_params]}",
            json: [json_mod_updates2014]
          )
          mod_updates1 = nexus_mods.updated_mods(game_domain_name: 'skyrimspecialedition', since: since_config[:since])
          mod_updates2 = nexus_mods.updated_mods(game_domain_name: 'skyrimspecialedition', since: since_config[:since])
          expect(mod_updates1.object_id).not_to eq mod_updates2.object_id
          expect(mod_updates1).to eq mod_updates2
        end

        it 'returns the mod associated to the mod updates' do
          expect_http_call_to(
            path: "/v1/games/skyrimspecialedition/mods/updated.json?#{since_config[:expected_url_params]}",
            json: [
              json_mod_updates2014
            ]
          )
          expect_http_call_to(
            path: '/v1/games/skyrimspecialedition/mods/2014.json',
            json: json_complete_mod
          )
          expect_mod_to_be_complete(nexus_mods.updated_mods(game_domain_name: 'skyrimspecialedition', since: since_config[:since]).first.mod)
        end

        it 'returns the mod files associated to the mod updates' do
          expect_http_call_to(
            path: "/v1/games/skyrimspecialedition/mods/updated.json?#{since_config[:expected_url_params]}",
            json: [
              json_mod_updates2014
            ]
          )
          expect_http_call_to(
            path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
            json: { 'files' => [json_mod_file2472] }
          )
          expect_mod_file_to_be2472(nexus_mods.updated_mods(game_domain_name: 'skyrimspecialedition', since: since_config[:since]).first.mod_files.first)
        end

      end

    end

    it 'fails to fetch updated mods for an unknown period' do
      expect { nexus_mods.updated_mods(game_domain_name: 'skyrimspecialedition', since: :unknown_since) }.to raise_error 'Unknown time stamp: unknown_since'
    end

  end

end
