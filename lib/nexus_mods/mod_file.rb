class NexusMods

  # A NexusMods file.
  # Attributes info can be taken from there:
  # * https://github.com/Nexus-Mods/node-nexus-api/blob/master/docs/interfaces/_types_.ifileinfo.md
  class ModFile

    attr_reader(*%i[
      ids
      uid
      id
      name
      version
      category_id
      category_name
      is_primary
      size
      file_name
      uploaded_time
      mod_version
      external_virus_scan_url
      description
      changelog_html
      content_preview_url
    ])

    # Constructor
    #
    # Parameters::
    # * *ids* (Array<Integer>): The file's list of IDs
    # * *uid* (Integer): The file's UID
    # * *id* (Integer): The file's main ID
    # * *name* (String): The file's name
    # * *version* (String): The file's version
    # * *category_id* (Symbol): The file's category's ID
    # * *category_name* (String): The file's category_name
    # * *is_primary* (String): Is this file the primary download one?
    # * *size* (Integer): The file's size (in bytes)
    # * *file_name* (String): The file's exact file name
    # * *uploaded_time* (Time): The file's uploaded time
    # * *mod_version* (String): The file's mod version
    # * *external_virus_scan_url* (String): The URL of virus scan for this file
    # * *description* (String): The file's description
    # * *changelog_html* (String): The file's change log in HTML
    # * *content_preview_url* (String): URL to a JSON that gives info on the file's content
    def initialize(
      ids:,
      uid:,
      id:,
      name:,
      version:,
      category_id:,
      category_name:,
      is_primary:,
      size:,
      file_name:,
      uploaded_time:,
      mod_version:,
      external_virus_scan_url:,
      description:,
      changelog_html:,
      content_preview_url:
    )
      @ids = ids
      @uid = uid
      @id = id
      @name = name
      @version = version
      @category_id = category_id
      @category_name = category_name
      @is_primary = is_primary
      @size = size
      @file_name = file_name
      @uploaded_time = uploaded_time
      @mod_version = mod_version
      @external_virus_scan_url = external_virus_scan_url
      @description = description
      @changelog_html = changelog_html
      @content_preview_url = content_preview_url
    end

  end

end
