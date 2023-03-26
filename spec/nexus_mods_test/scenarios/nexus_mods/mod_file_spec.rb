describe NexusMods::ModFile do

  context 'when testing mod files' do

    # Example of JSON object returned by the API for a mod files list
    let(:json_example_mod_files) do
      [
        {
          'id' => [
            2472,
            1704
          ],
          'uid' => 7_318_624_274_856,
          'file_id' => 2472,
          'name' => 'ApachiiSkyHair_v_1_6_Full',
          'version' => '1.6.Full',
          'category_id' => 4,
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
        },
        {
          'id' => [
            2487,
            1705
          ],
          'uid' => 7_318_624_274_857,
          'file_id' => 2487,
          'name' => 'ApachiiSkyHairMale_v_1_2',
          'version' => '1.2',
          'category_id' => 4,
          'category_name' => 'OLD_VERSION',
          'is_primary' => false,
          'file_name' => 'ApachiiSkyHairMale_v_1_2-2014-1-2.7z',
          'uploaded_timestamp' => 1_477_968_373,
          'uploaded_time' => '2016-11-01T02:46:13.000+00:00',
          'mod_version' => '1.2',
          'external_virus_scan_url' => 'https://www.virustotal.com/file/3e86106233499ac43383c32ce4a2d8e162dc6e940b4d228f649a701b71ee5676/analysis/1477979366/',
          'description' => 'NOT optimezed meshes. Standalone 55 Male hairs -  Not included in ApachiiSkyHair v_1_6_Full ',
          'size' => 204_347,
          'size_kb' => 204_347,
          'size_in_bytes' => 209_251_227,
          'changelog_html' => nil,
          'content_preview_link' => 'https://file-metadata.nexusmods.com/file/nexus-files-meta/1704/2014/ApachiiSkyHairMale_v_1_2-2014-1-2.7z.json'
        }
      ]
    end

    # Expect a mod's files to be the example ones
    #
    # Parameters::
    # * *mod_files* (Array<NexusMods::File>): List of files to validate
    def expect_mod_files_to_be_example(mod_files)
      expect(mod_files.size).to eq 2
      sorted_mod_files = mod_files.sort_by(&:id)
      first_mod_file = sorted_mod_files.first
      expect(first_mod_file.ids).to eq [2472, 1704]
      expect(first_mod_file.uid).to eq 7_318_624_274_856
      expect(first_mod_file.id).to eq 2472
      expect(first_mod_file.name).to eq 'ApachiiSkyHair_v_1_6_Full'
      expect(first_mod_file.version).to eq '1.6.Full'
      expect(first_mod_file.category_id).to eq :old
      expect(first_mod_file.category_name).to eq 'OLD_VERSION'
      expect(first_mod_file.is_primary).to be false
      expect(first_mod_file.size).to eq 309_251_227
      expect(first_mod_file.file_name).to eq 'ApachiiSkyHair_v_1_6_Full-2014-1-6-Full.7z'
      expect(first_mod_file.uploaded_time).to eq Time.parse('2016-11-01T02:34:05.000+00:00')
      expect(first_mod_file.mod_version).to eq '1.6.Full'
      expect(first_mod_file.external_virus_scan_url).to eq 'https://www.virustotal.com/file/3dcc96dce0b846ea643d626c48bd6ad08752da8232f3d29be644d36e1fd627cf/analysis/1477978674/'
      expect(first_mod_file.description).to eq '[b][color=orange] NOT optimized meshes. Standalone. Adds 42 new hairstyles for females, 21 hair for males and 5 hairs for Female Khajiit- 2 hairs for Male Khajiit[/color][/b]  '
      expect(first_mod_file.changelog_html).to be_nil
      expect(first_mod_file.content_preview_url).to eq 'https://file-metadata.nexusmods.com/file/nexus-files-meta/1704/2014/ApachiiSkyHair_v_1_6_Full-2014-1-6-Full.7z.json'
      second_mod_file = sorted_mod_files[1]
      expect(second_mod_file.ids).to eq [2487, 1705]
      expect(second_mod_file.uid).to eq 7_318_624_274_857
      expect(second_mod_file.id).to eq 2487
      expect(second_mod_file.name).to eq 'ApachiiSkyHairMale_v_1_2'
      expect(second_mod_file.version).to eq '1.2'
      expect(second_mod_file.category_id).to eq :old
      expect(second_mod_file.category_name).to eq 'OLD_VERSION'
      expect(second_mod_file.is_primary).to be false
      expect(second_mod_file.size).to eq 209_251_227
      expect(second_mod_file.file_name).to eq 'ApachiiSkyHairMale_v_1_2-2014-1-2.7z'
      expect(second_mod_file.uploaded_time).to eq Time.parse('2016-11-01T02:46:13.000+00:00')
      expect(second_mod_file.mod_version).to eq '1.2'
      expect(second_mod_file.external_virus_scan_url).to eq 'https://www.virustotal.com/file/3e86106233499ac43383c32ce4a2d8e162dc6e940b4d228f649a701b71ee5676/analysis/1477979366/'
      expect(second_mod_file.description).to eq 'NOT optimezed meshes. Standalone 55 Male hairs -  Not included in ApachiiSkyHair v_1_6_Full '
      expect(second_mod_file.changelog_html).to be_nil
      expect(second_mod_file.content_preview_url).to eq 'https://file-metadata.nexusmods.com/file/nexus-files-meta/1704/2014/ApachiiSkyHairMale_v_1_2-2014-1-2.7z.json'
    end

    it 'returns a mod files list' do
      expect_validate_user
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
        json: { files: json_example_mod_files }
      )
      expect_mod_files_to_be_example(nexus_mods.mod_files(game_domain_name: 'skyrimspecialedition', mod_id: 2014))
    end

    it 'returns the default mod files list' do
      expect_validate_user
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
        json: { files: json_example_mod_files }
      )
      expect_mod_files_to_be_example(nexus_mods(mod_id: 2014).mod_files(game_domain_name: 'skyrimspecialedition'))
    end

    it 'returns mod files list for the default game' do
      expect_validate_user
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
        json: { files: json_example_mod_files }
      )
      expect_mod_files_to_be_example(nexus_mods(game_domain_name: 'skyrimspecialedition').mod_files(mod_id: 2014))
    end

    it 'returns mod files list for the default game and mod' do
      expect_validate_user
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
        json: { files: json_example_mod_files }
      )
      expect_mod_files_to_be_example(nexus_mods(game_domain_name: 'skyrimspecialedition', mod_id: 2014).mod_files)
    end

  end

end
