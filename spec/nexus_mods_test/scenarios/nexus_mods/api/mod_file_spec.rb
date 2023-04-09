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

    it 'returns mod files list for the default game and mod' do
      expect_http_call_to(
        path: '/v1/games/skyrimspecialedition/mods/2014/files.json',
        json: { files: json_example_mod_files }
      )
      expect_mod_files_to_be_example(nexus_mods(game_domain_name: 'skyrimspecialedition', mod_id: 2014).mod_files)
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

  end

end
