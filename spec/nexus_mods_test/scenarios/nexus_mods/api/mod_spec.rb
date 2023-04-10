describe NexusMods::Api::Mod do

  context 'when testing mods' do

    before do
      expect_validate_user
    end

    it 'returns a mod complete information' do
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014.json',
        json: json_complete_mod
      )
      expect_mod_to_be_complete(nexus_mods.mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014))
    end

    it 'returns a mod partial information' do
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014.json',
        json: json_partial_mod
      )
      expect_mod_to_be_partial(nexus_mods.mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014))
    end

    it 'returns the default mod information' do
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014.json',
        json: json_complete_mod
      )
      expect_mod_to_be_complete(nexus_mods(mod_id: 2014).mod(game_domain_name: 'skyrimspecialedition'))
    end

    it 'returns mod information for the default game' do
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014.json',
        json: json_complete_mod
      )
      expect_mod_to_be_complete(nexus_mods(game_domain_name: 'skyrimspecialedition').mod(mod_id: 2014))
    end

    it 'returns mod information for the default game set using accessor' do
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014.json',
        json: json_complete_mod
      )
      nexus_mods.game_domain_name = 'skyrimspecialedition'
      expect_mod_to_be_complete(nexus_mods.mod(mod_id: 2014))
    end

    it 'returns mod information for the default game and mod' do
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014.json',
        json: json_complete_mod
      )
      expect_mod_to_be_complete(nexus_mods(game_domain_name: 'skyrimspecialedition', mod_id: 2014).mod)
    end

    it 'returns mod information for the default game and mod set using accessor' do
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014.json',
        json: json_complete_mod
      )
      nexus_mods.mod_id = 2014
      expect_mod_to_be_complete(nexus_mods.mod(game_domain_name: 'skyrimspecialedition'))
    end

    it 'compares objects for equality' do
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014.json',
        json: json_complete_mod
      )
      mod1 = nexus_mods.mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014)
      mod2 = nexus_mods.mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014)
      expect(mod1.object_id).not_to eq mod2.object_id
      expect(mod1).to eq mod2
    end

  end

end
