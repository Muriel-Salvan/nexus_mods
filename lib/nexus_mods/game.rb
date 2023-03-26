class NexusMods

  # A NexusMods game.
  # Attributes info can be taken from there:
  # * https://github.com/Nexus-Mods/node-nexus-api/blob/master/docs/interfaces/_types_.igameinfo.md
  class Game

    attr_reader(
      *%i[
        id
        name
        forum_url
        nexusmods_url
        genre
        domain_name
        approved_date
        files_count
        files_views
        files_endorsements
        downloads_count
        authors_count
        mods_count
        categories
      ]
    )

    # Constructor
    #
    # Parameters::
    # * *id* (Integer): The game's id
    # * *name* (String): The game's name
    # * *forum_url* (String): The game's forum's URL
    # * *nexusmods_url* (String): The game's NexusMods' URL
    # * *genre* (String): The game's genre
    # * *domain_name* (String): The game's domain's name
    # * *approved_date* (Time): The game's approved date (time when the game was added)
    # * *files_count* (Integer): The game's files' count [default: 0]
    # * *files_views* (Integer): The game's files' views [default: 0]
    # * *files_endorsements* (Integer): The game's files' endorsements [default: 0]
    # * *downloads_count* (Integer): The game's downloads' count [default: 0]
    # * *authors_count* (Integer): The game's authors's count [default: 0]
    # * *mods_count* (Integer): The game's mods' count [default: 0]
    # * *categories* (Array<Category>): The list of game's categories [default: []]
    def initialize(
      id:,
      name:,
      forum_url:,
      nexusmods_url:,
      genre:,
      domain_name:,
      approved_date:,
      files_count: 0,
      files_views: 0,
      files_endorsements: 0,
      downloads_count: 0,
      authors_count: 0,
      mods_count: 0,
      categories: []
    )
      @id = id
      @name = name
      @forum_url = forum_url
      @nexusmods_url = nexusmods_url
      @genre = genre
      @domain_name = domain_name
      @approved_date = approved_date
      @files_count = files_count
      @files_views = files_views
      @files_endorsements = files_endorsements
      @downloads_count = downloads_count
      @authors_count = authors_count
      @mods_count = mods_count
      @categories = categories
    end

  end

end
