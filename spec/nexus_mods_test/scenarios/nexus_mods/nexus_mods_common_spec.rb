describe NexusMods do

  context 'when testing authentication and access' do

    it 'returns the default game domain name' do
      expect_validate_user
      expect(nexus_mods(game_domain_name: 'skyrimspecialedition').game_domain_name).to eq 'skyrimspecialedition'
    end

    it 'returns the default game mod id' do
      expect_validate_user
      expect(nexus_mods(mod_id: 2014).mod_id).to eq 2014
    end

    it 'accepts the log level' do
      expect_validate_user(times: 2)
      expect_http_call_to(
        path: '/v1/games.json',
        json: [],
        times: 2
      )
      nexus_mods(log_level: :debug).games
      log_debug = nexus_mods_logs
      reset_nexus_mods
      nexus_mods(log_level: :info).games
      log_info = nexus_mods_logs
      expect(log_debug.size).to be > log_info.size
    end

  end

end
