describe NexusMods do

  context 'testing access' do

    it 'gets api limits' do
      expect_validate_user
      expect_validate_user
      api_limits = nexus_mods.api_limits
      expect(api_limits.daily_limit).to eq 2500
      expect(api_limits.daily_remaining).to eq 2500
      expect(api_limits.daily_reset).to eq Time.parse('2019-10-03 00:00:00 +0000')
      expect(api_limits.hourly_limit).to eq 100
      expect(api_limits.hourly_remaining).to eq 100
      expect(api_limits.hourly_reset).to eq Time.parse('2019-10-02T16:00:00+00:00')
    end

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
