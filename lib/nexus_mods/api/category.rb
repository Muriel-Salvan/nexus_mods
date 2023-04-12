require 'nexus_mods/api/resource'

class NexusMods

  module Api

    # Categories defined for a game in NexusMods
    class Category < Resource

      attr_reader(
        *%i[
          id
          name
        ]
      )

      attr_accessor(
        *%i[
          parent_category
        ]
      )

      # Constructor
      #
      # Parameters::
      # * *nexus_mods* (NexusMods): The NexusMods API instance that the resource can use to query for other resources
      # *id* (Integer): The category id
      # *name* (String): The category id
      # *parent_category* (Category or nil): The parent category, or nil if none [default: nil]
      def initialize(
        nexus_mods:,
        id:,
        name:,
        parent_category: nil
      )
        super(nexus_mods:)
        @id = id
        @name = name
        @parent_category = parent_category
      end

      # Equality operator
      #
      # Parameters::
      # * *other* (Object): Other object to compare with
      # Result::
      # * Boolean: Are objects equal?
      def ==(other)
        other.is_a?(Category) &&
          @id == other.id &&
          @name == other.name &&
          @parent_category == other.parent_category
      end

    end

  end

end
