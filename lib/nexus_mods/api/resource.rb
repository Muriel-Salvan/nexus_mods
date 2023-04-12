class NexusMods

  module Api

    # Base class for any API resource
    class Resource

      # Constructor
      #
      # Parameters::
      # * *nexus_mods* (NexusMods): The NexusMods API instance that the resource can use to query for other resources
      def initialize(nexus_mods:)
        @nexus_mods = nexus_mods
      end

    end

  end

end
