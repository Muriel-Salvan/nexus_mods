describe NexusMods::Api::ApiLimits do

  context 'when testing API limits' do

    it 'gets api limits' do
      expect_validate_user(times: 2)
      api_limits = nexus_mods.api_limits
      expect(api_limits.daily_limit).to eq 2500
      expect(api_limits.daily_remaining).to eq 2500
      expect(api_limits.daily_reset).to eq Time.parse('2019-10-03 00:00:00 +0000')
      expect(api_limits.hourly_limit).to eq 100
      expect(api_limits.hourly_remaining).to eq 100
      expect(api_limits.hourly_reset).to eq Time.parse('2019-10-02T16:00:00+00:00')
    end

    it 'compares objects for equality' do
      expect_validate_user(times: 3)
      api_limits1 = nexus_mods.api_limits
      api_limits2 = nexus_mods.api_limits
      expect(api_limits1.object_id).not_to eq api_limits2.object_id
      expect(api_limits1).to eq api_limits2
    end

  end

end
