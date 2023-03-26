class NexusMods

  # Categories defined for a game in NexusMods
  class Category

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
    # *id* (Integer): The category id
    # *name* (String): The category id
    # *parent_category* (Category or nil): The parent category, or nil if none [default: nil]
    def initialize(
      id:,
      name:,
      parent_category: nil
    )
      @id = id
      @name = name
      @parent_category = parent_category
    end

  end

end
