class NexusMods

  module Api

    # A user on NExusMods.
    # Mainly used for uploaders information.
    class User

      attr_reader(
        *%i[
          member_id
          member_group_id
          name
          profile_url
        ]
      )

      # Constructor
      #
      # Parameters::
      # * *member_id* (Integer): The user's member id
      # * *member_group_id* (Integer): The user's member group id
      # * *name* (String): The user's name
      # * *profile_url* (String): The user's profile URL
      def initialize(
        member_id:,
        member_group_id:,
        name:,
        profile_url:
      )
        @member_id = member_id
        @member_group_id = member_group_id
        @name = name
        @profile_url = profile_url
      end

      # Equality operator
      #
      # Parameters::
      # * *other* (Object): Other object to compare with
      # Result::
      # * Boolean: Are objects equal?
      def ==(other)
        other.is_a?(User) &&
          @member_id == other.member_id &&
          @member_group_id == other.member_group_id &&
          @name == other.name &&
          @profile_url == other.profile_url
      end

    end

  end

end
