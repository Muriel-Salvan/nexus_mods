describe NexusMods::Api::Game do

  context 'when testing games' do

    before do
      expect_validate_user
    end

    it 'returns the games list' do
      expect_http_call_to(
        path: '/v1/games.json',
        json: [
          json_game100,
          json_game101
        ]
      )
      games = nexus_mods.games.sort_by(&:id)
      expect(games.size).to eq 2
      expect_game_to_be_game100(games.first)
      expect_game_to_be_game101(games[1])
    end

    it 'returns a game having missing parent category' do
      expect_http_call_to(
        path: '/v1/games.json',
        json: [
          {
            'id' => 100,
            'name' => 'Morrowind',
            'forum_url' => 'https://forums.nexusmods.com/index.php?/forum/111-morrowind/',
            'nexusmods_url' => 'http://www.nexusmods.com/morrowind',
            'genre' => 'RPG',
            'file_count' => 14_143,
            'downloads' => 20_414_985,
            'domain_name' => 'morrowind',
            'approved_date' => 1,
            'file_views' => 100_014_750,
            'authors' => 2062,
            'file_endorsements' => 719_262,
            'mods' => 6080,
            'categories' => [
              {
                'category_id' => 1,
                'name' => 'Morrowind',
                'parent_category' => false
              },
              {
                'category_id' => 2,
                'name' => 'Buildings',
                'parent_category' => 3
              }
            ]
          }
        ]
      )
      game = nexus_mods.games.first
      expect(game.id).to eq 100
      expect(game.name).to eq 'Morrowind'
      expect(game.forum_url).to eq 'https://forums.nexusmods.com/index.php?/forum/111-morrowind/'
      expect(game.nexusmods_url).to eq 'http://www.nexusmods.com/morrowind'
      expect(game.genre).to eq 'RPG'
      expect(game.files_count).to eq 14_143
      expect(game.downloads_count).to eq 20_414_985
      expect(game.domain_name).to eq 'morrowind'
      expect(game.approved_date).to eq Time.parse('1970-01-01 00:00:01 +0000')
      expect(game.files_views).to eq 100_014_750
      expect(game.authors_count).to eq 2062
      expect(game.files_endorsements).to eq 719_262
      expect(game.mods_count).to eq 6080
      game_categories = game.categories
      expect(game_categories.size).to eq 2
      expect(game_categories.first.id).to eq 1
      expect(game_categories.first.name).to eq 'Morrowind'
      expect(game_categories.first.parent_category).to be_nil
      expect(game_categories[1].id).to eq 2
      expect(game_categories[1].name).to eq 'Buildings'
      expect(game_categories[1].parent_category).to be_nil
    end

    it 'compares objects for equality' do
      expect_http_call_to(
        path: '/v1/games.json',
        json: [json_game100]
      )
      game1 = nexus_mods.games.first
      game2 = nexus_mods.games.first
      expect(game1.object_id).not_to eq game2.object_id
      expect(game1).to eq game2
    end

  end

end
