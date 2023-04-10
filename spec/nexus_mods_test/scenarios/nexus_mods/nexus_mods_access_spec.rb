describe NexusMods do

  context 'when testing authentication and access' do

    it 'fails with an exception if the API key is invalid' do
      expect_http_call_to(
        path: '/v1/users/validate.json',
        api_key: 'wrong_api_key',
        code: 401,
        json: {
          message: 'Please provide a valid API Key'
        }
      )
      expect { nexus_mods(api_key: 'wrong_api_key') }.to raise_error(NexusMods::InvalidApiKeyError)
    end

    it 'fails with an exception if the API limits have been reached' do
      expect_http_call_to(
        path: '/v1/users/validate.json',
        code: 429
      )
      expect { nexus_mods }.to raise_error(NexusMods::LimitsExceededError)
    end

    it 'fails with an exception if the API limits have been reached during usage' do
      expect_validate_user
      expect_http_call_to(
        path: '/v1/games.json',
        code: 429
      )
      nexus_mods
      expect { nexus_mods.games }.to raise_error(NexusMods::LimitsExceededError)
    end

  end

end
