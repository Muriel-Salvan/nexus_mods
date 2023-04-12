module NexusModsTest

  module Factories

    module ModUpdates

      # Test mod updates with id 2014
      def self.json_mod_updates2014
        {
          'mod_id' => 2014,
          'latest_file_update' => 1_655_813_855,
          'latest_mod_activity' => 1_681_169_675
        }
      end

      def json_mod_updates2014
        ModUpdates.json_mod_updates2014
      end

      # Test mod updates with id 100
      def self.json_mod_updates100
        {
          'mod_id' => 100,
          'latest_file_update' => 1_681_143_964,
          'latest_mod_activity' => 1_681_143_964
        }
      end

      def json_mod_updates100
        ModUpdates.json_mod_updates100
      end

      # Expect a mod's updates to be the example one with id 2014
      #
      # Parameters::
      # * *mod_updates* (NexusMods::Api::ModUpdates): Mod updates to validate
      def expect_mod_file_to_be2014(mod_updates)
        expect(mod_updates.mod_id).to eq 2014
        expect(mod_updates.latest_file_update).to eq Time.parse('2022-06-21 12:17:35 UTC')
        expect(mod_updates.latest_mod_activity).to eq Time.parse('2023-04-10 23:34:35 UTC')
      end

      # Expect a mod's updates to be the example one with id 100
      #
      # Parameters::
      # * *mod_updates* (NexusMods::Api::ModUpdates): Mod updates to validate
      def expect_mod_file_to_be100(mod_updates)
        expect(mod_updates.mod_id).to eq 100
        expect(mod_updates.latest_file_update).to eq Time.parse('2023-04-10 16:26:04 UTC')
        expect(mod_updates.latest_mod_activity).to eq Time.parse('2023-04-10 16:26:04 UTC')
      end

    end

  end

end
