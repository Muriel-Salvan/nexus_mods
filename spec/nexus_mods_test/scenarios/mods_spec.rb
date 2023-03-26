describe NexusMods do

  context 'testing mods' do

    # Example of JSON object returned by the API for a mod information, having all possible fields
    JSON_COMPLETE_MOD = {
      'name' => 'ApachiiSkyHair SSE',
      'summary' => 'New Female and Male Hairstyles for Humans, Elves and Orcs. Converted hair from Sims2 and Sims3.<br />Standalone version.',
      'description' => 'Mod description',
      'picture_url' => 'https://staticdelivery.nexusmods.com/mods/1704/images/10168-1-1392817986.jpg',
      'mod_downloads': 13634545,
      'mod_unique_downloads': 4052221,
      'uid': 7318624272650,
      'mod_id' => 2014,
      'game_id' => 1704,
      'allow_rating': true,
      'domain_name' => 'skyrimspecialedition',
      'category_id' => 26,
      'version' => '1.6.Full',
      'endorsement_count': 298845,
      'created_timestamp' => 1477972056,
      'created_time' => '2016-11-01T03:47:36.000+00:00',
      'updated_timestamp' => 1507398546,
      'updated_time' => '2017-10-07T17:49:06.000+00:00',
      'author' => 'Apachii',
      'uploaded_by' => 'apachii',
      'uploaded_users_profile_url' => 'http://www.nexusmods.com/games/users/283148',
      'contains_adult_content' => false,
      'status' => 'published',
      'available' => true,
      'user' => {
        'member_id' => 283148,
        'member_group_id' => 27,
        'name' => 'apachii'
      },
      'endorsement' => {
        'endorse_status' => 'Undecided',
        'timestamp' => nil,
        'version' => nil
      }
    }

    # Example of JSON object returned by the API for a mod information, having minimum fields
    JSON_PARTIAL_MOD = {
      'mod_downloads': 13634545,
      'mod_unique_downloads': 4052221,
      'uid': 7318624272650,
      'mod_id' => 2014,
      'game_id' => 1704,
      'allow_rating': true,
      'domain_name' => 'skyrimspecialedition',
      'category_id' => 26,
      'version' => '1.6.Full',
      'endorsement_count': 298845,
      'created_timestamp' => 1477972056,
      'created_time' => '2016-11-01T03:47:36.000+00:00',
      'updated_timestamp' => 1507398546,
      'updated_time' => '2017-10-07T17:49:06.000+00:00',
      'author' => 'Apachii',
      'uploaded_by' => 'apachii',
      'uploaded_users_profile_url' => 'http://www.nexusmods.com/games/users/283148',
      'contains_adult_content' => false,
      'status' => 'published',
      'available' => true,
      'user' => {
        'member_id' => 283148,
        'member_group_id' => 27,
        'name' => 'apachii'
      }
    }

    # Expect a mod to be the example complete one
    #
    # Parameters::
    # * *mod* (NexusMods::Mod): Mod to validate
    def expect_mod_to_be_complete(mod)
      expect(mod.name).to eq 'ApachiiSkyHair SSE'
      expect(mod.summary).to eq 'New Female and Male Hairstyles for Humans, Elves and Orcs. Converted hair from Sims2 and Sims3.<br />Standalone version.'
      expect(mod.description).to eq 'Mod description'
      expect(mod.picture_url).to eq 'https://staticdelivery.nexusmods.com/mods/1704/images/10168-1-1392817986.jpg'
      expect(mod.downloads_count).to eq 13634545
      expect(mod.unique_downloads_count).to eq 4052221
      expect(mod.uid).to eq 7318624272650
      expect(mod.mod_id).to eq 2014
      expect(mod.game_id).to eq 1704
      expect(mod.allow_rating).to eq true
      expect(mod.domain_name).to eq 'skyrimspecialedition'
      expect(mod.category_id).to eq 26
      expect(mod.version).to eq '1.6.Full'
      expect(mod.endorsements_count).to eq 298845
      expect(mod.created_time).to eq Time.parse('2016-11-01T03:47:36.000+00:00')
      expect(mod.updated_time).to eq Time.parse('2017-10-07T17:49:06.000+00:00')
      expect(mod.author).to eq 'Apachii'
      expect(mod.contains_adult_content).to eq false
      expect(mod.status).to eq 'published'
      expect(mod.available).to eq true
      expect(mod.uploader.member_id).to eq 283148
      expect(mod.uploader.member_group_id).to eq 27
      expect(mod.uploader.name).to eq 'apachii'
      expect(mod.uploader.profile_url).to eq 'http://www.nexusmods.com/games/users/283148'
    end

    # Expect a mod to be the example partial one
    #
    # Parameters::
    # * *mod* (NexusMods::Mod): Mod to validate
    def expect_mod_to_be_partial(mod)
      expect(mod.name).to be_nil
      expect(mod.summary).to be_nil
      expect(mod.description).to be_nil
      expect(mod.picture_url).to be_nil
      expect(mod.downloads_count).to eq 13634545
      expect(mod.unique_downloads_count).to eq 4052221
      expect(mod.uid).to eq 7318624272650
      expect(mod.mod_id).to eq 2014
      expect(mod.game_id).to eq 1704
      expect(mod.allow_rating).to eq true
      expect(mod.domain_name).to eq 'skyrimspecialedition'
      expect(mod.category_id).to eq 26
      expect(mod.version).to eq '1.6.Full'
      expect(mod.endorsements_count).to eq 298845
      expect(mod.created_time).to eq Time.parse('2016-11-01T03:47:36.000+00:00')
      expect(mod.updated_time).to eq Time.parse('2017-10-07T17:49:06.000+00:00')
      expect(mod.author).to eq 'Apachii'
      expect(mod.contains_adult_content).to eq false
      expect(mod.status).to eq 'published'
      expect(mod.available).to eq true
      expect(mod.uploader.member_id).to eq 283148
      expect(mod.uploader.member_group_id).to eq 27
      expect(mod.uploader.name).to eq 'apachii'
      expect(mod.uploader.profile_url).to eq 'http://www.nexusmods.com/games/users/283148'
    end

    it 'returns a mod complete information' do
      expect_validate_user
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014.json',
        json: JSON_COMPLETE_MOD
      )
      expect_mod_to_be_complete(nexus_mods.mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014))
    end

    it 'returns a mod partial information' do
      expect_validate_user
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014.json',
        json: JSON_PARTIAL_MOD
      )
      expect_mod_to_be_partial(nexus_mods.mod(game_domain_name: 'skyrimspecialedition', mod_id: 2014))
    end

    it 'returns the default mod information' do
      expect_validate_user
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014.json',
        json: JSON_COMPLETE_MOD
      )
      expect_mod_to_be_complete(nexus_mods(mod_id: 2014).mod(game_domain_name: 'skyrimspecialedition'))
    end

    it 'returns mod information for the default game' do
      expect_validate_user
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014.json',
        json: JSON_COMPLETE_MOD
      )
      expect_mod_to_be_complete(nexus_mods(game_domain_name: 'skyrimspecialedition').mod(mod_id: 2014))
    end

    it 'returns mod information for the default game and mod' do
      expect_validate_user
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014.json',
        json: JSON_COMPLETE_MOD
      )
      expect_mod_to_be_complete(nexus_mods(game_domain_name: 'skyrimspecialedition', mod_id: 2014).mod)
    end

  end

end
