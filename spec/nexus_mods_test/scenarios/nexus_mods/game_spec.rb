describe NexusMods::Game do

  context 'when testing games' do

    it 'returns the games list' do
      expect_validate_user
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
                'parent_category' => 1
              }
            ]
          },
          {
            'id' => 101,
            'name' => 'Oblivion',
            'forum_url' => 'https://forums.nexusmods.com/index.php?/forum/131-oblivion/',
            'nexusmods_url' => 'http://www.nexusmods.com/oblivion',
            'genre' => 'RPG',
            'file_count' => 52_775,
            'downloads' => 187_758_634,
            'domain_name' => 'oblivion',
            'approved_date' => 1,
            'file_views' => 880_508_188,
            'authors' => 10_673,
            'file_endorsements' => 4_104_067,
            'mods' => 29_220,
            'categories' => [
              {
                'category_id' => 20,
                'name' => 'Oblivion',
                'parent_category' => false
              },
              {
                'category_id' => 22,
                'name' => 'New structures - Buildings',
                'parent_category' => 20
              }
            ]
          }
        ]
      )
      games = nexus_mods.games.sort_by(&:id)
      expect(games.size).to eq 2
      first_game = games.first
      expect(first_game.id).to eq 100
      expect(first_game.name).to eq 'Morrowind'
      expect(first_game.forum_url).to eq 'https://forums.nexusmods.com/index.php?/forum/111-morrowind/'
      expect(first_game.nexusmods_url).to eq 'http://www.nexusmods.com/morrowind'
      expect(first_game.genre).to eq 'RPG'
      expect(first_game.files_count).to eq 14_143
      expect(first_game.downloads_count).to eq 20_414_985
      expect(first_game.domain_name).to eq 'morrowind'
      expect(first_game.approved_date).to eq Time.parse('1970-01-01 00:00:01 +0000')
      expect(first_game.files_views).to eq 100_014_750
      expect(first_game.authors_count).to eq 2062
      expect(first_game.files_endorsements).to eq 719_262
      expect(first_game.mods_count).to eq 6080
      first_game_categories = first_game.categories
      expect(first_game_categories.size).to eq 2
      expect(first_game_categories.first.id).to eq 1
      expect(first_game_categories.first.name).to eq 'Morrowind'
      expect(first_game_categories.first.parent_category).to be_nil
      expect(first_game_categories[1].id).to eq 2
      expect(first_game_categories[1].name).to eq 'Buildings'
      expect(first_game_categories[1].parent_category).not_to be_nil
      expect(first_game_categories[1].parent_category.id).to eq 1
      expect(first_game_categories[1].parent_category.name).to eq 'Morrowind'
      expect(first_game_categories[1].parent_category.parent_category).to be_nil
      second_game = games[1]
      expect(second_game.id).to eq 101
      expect(second_game.name).to eq 'Oblivion'
      expect(second_game.forum_url).to eq 'https://forums.nexusmods.com/index.php?/forum/131-oblivion/'
      expect(second_game.nexusmods_url).to eq 'http://www.nexusmods.com/oblivion'
      expect(second_game.genre).to eq 'RPG'
      expect(second_game.files_count).to eq 52_775
      expect(second_game.downloads_count).to eq 187_758_634
      expect(second_game.domain_name).to eq 'oblivion'
      expect(second_game.approved_date).to eq Time.parse('1970-01-01 00:00:01 +0000')
      expect(second_game.files_views).to eq 880_508_188
      expect(second_game.authors_count).to eq 10_673
      expect(second_game.files_endorsements).to eq 4_104_067
      expect(second_game.mods_count).to eq 29_220
      second_game_categories = second_game.categories
      expect(second_game_categories.size).to eq 2
      expect(second_game_categories.first.id).to eq 20
      expect(second_game_categories.first.name).to eq 'Oblivion'
      expect(second_game_categories.first.parent_category).to be_nil
      expect(second_game_categories[1].id).to eq 22
      expect(second_game_categories[1].name).to eq 'New structures - Buildings'
      expect(second_game_categories[1].parent_category).not_to be_nil
      expect(second_game_categories[1].parent_category.id).to eq 20
      expect(second_game_categories[1].parent_category.name).to eq 'Oblivion'
      expect(second_game_categories[1].parent_category.parent_category).to be_nil
    end

    it 'returns a game having missing parent category' do
      expect_validate_user
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

  end

end
