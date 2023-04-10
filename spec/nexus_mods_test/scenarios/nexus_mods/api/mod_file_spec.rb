describe NexusMods::Api::ModFile do

  context 'when testing mod files' do

    before do
      expect_validate_user
    end

    # Example of JSON object returned by the API for a mod files list
    let(:json_example_mod_files) do
      [
        json_mod_file2472,
        json_mod_file2487
      ]
    end

    # Expect a mod's files to be the example ones
    #
    # Parameters::
    # * *mod_files* (Array<NexusMods::Api::File>): List of files to validate
    def expect_mod_files_to_be_example(mod_files)
      expect(mod_files.size).to eq 2
      sorted_mod_files = mod_files.sort_by(&:id)
      expect_mod_file_to_be2472(sorted_mod_files.first)
      expect_mod_file_to_be2487(sorted_mod_files[1])
    end

    it 'returns a mod files list' do
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
        json: { files: json_example_mod_files }
      )
      expect_mod_files_to_be_example(nexus_mods.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2014))
    end

    it 'returns the default mod files list' do
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
        json: { files: json_example_mod_files }
      )
      expect_mod_files_to_be_example(nexus_mods(mod_id: 2014).mod_files(game_domain_name: 'skyrimspecialedition'))
    end

    it 'returns mod files list for the default game' do
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
        json: { files: json_example_mod_files }
      )
      expect_mod_files_to_be_example(nexus_mods(game_domain_name: 'skyrimspecialedition').mod_files(mod_id: 2014))
    end

    it 'returns mod files list for the default game set using accessor' do
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
        json: { files: json_example_mod_files }
      )
      nexus_mods.game_domain_name = 'skyrimspecialedition'
      expect_mod_files_to_be_example(nexus_mods.mod_files(mod_id: 2014))
    end

    it 'returns mod files list for the default game and mod' do
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
        json: { files: json_example_mod_files }
      )
      expect_mod_files_to_be_example(nexus_mods(game_domain_name: 'skyrimspecialedition', mod_id: 2014).mod_files)
    end

    it 'returns mod files list for the default game and mod using accessor' do
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
        json: { files: json_example_mod_files }
      )
      nexus_mods.mod_id = 2014
      expect_mod_files_to_be_example(nexus_mods.mod_files(game_domain_name: 'skyrimspecialedition'))
    end

    it 'compares objects for equality' do
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
        json: { files: [json_mod_file2472] }
      )
      mod_file1 = nexus_mods(game_domain_name: 'skyrimspecialedition', mod_id: 2014).mod_files.first
      mod_file2 = nexus_mods(game_domain_name: 'skyrimspecialedition', mod_id: 2014).mod_files.first
      expect(mod_file1.object_id).not_to eq mod_file2.object_id
      expect(mod_file1).to eq mod_file2
    end

    {
      main: 1,
      patch: 2,
      optional: 3,
      old: 4,
      miscellaneous: 5,
      deleted: 6,
      archived: 7,
      unknown: 100
    }.each do |category, category_id|
      it "accepts mod files having category #{category}" do
        expect_http_call_to(
          path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
          json: {
            files: [
              {
                'id' => [
                  2472,
                  1704
                ],
                'uid' => 7_318_624_274_856,
                'file_id' => 2472,
                'name' => 'ApachiiSkyHair_v_1_6_Full',
                'version' => '1.6.Full',
                'category_id' => category_id,
                'category_name' => 'OLD_VERSION',
                'is_primary' => false,
                'file_name' => 'ApachiiSkyHair_v_1_6_Full-2014-1-6-Full.7z',
                'uploaded_timestamp' => 1_477_967_645,
                'uploaded_time' => '2016-11-01T02:34:05.000+00:00',
                'mod_version' => '1.6.Full',
                'external_virus_scan_url' => 'https://www.virustotal.com/file/3dcc96dce0b846ea643d626c48bd6ad08752da8232f3d29be644d36e1fd627cf/analysis/1477978674/',
                'description' => '[b][color=orange] NOT optimized meshes. Standalone. Adds 42 new hairstyles for females, 21 hair for males and 5 hairs for Female Khajiit- 2 hairs for Male Khajiit[/color][/b]  ',
                'size' => 304_347,
                'size_kb' => 304_347,
                'size_in_bytes' => 309_251_227,
                'changelog_html' => nil,
                'content_preview_link' => 'https://file-metadata.nexusmods.com/file/nexus-files-meta/1704/2014/ApachiiSkyHair_v_1_6_Full-2014-1-6-Full.7z.json'
              }
            ]
          }
        )
        mod_file = nexus_mods(game_domain_name: 'skyrimspecialedition', mod_id: 2014).mod_files.first
        expect(mod_file.category).to eq category
        expect(mod_file.category_id).to eq category_id
      end
    end

  end

end
