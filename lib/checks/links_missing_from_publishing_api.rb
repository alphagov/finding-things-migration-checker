module Checks
  class LinksMissingFromPublishingApi

    def initialize(checker_db, whitelist)
      @checker_db = checker_db
      @whitelist = whitelist
    end

    # find links present in Rummager which are not present in Publishing API

    def run_check
      publishing_api_links_query = <<-SQL
      SELECT
        pal.link_type,
        pal.link_content_id,
        pal.content_id,
        pac.publishing_app,
        pac.format
      FROM publishing_api_link pal
      JOIN publishing_api_content pac ON pal.content_id = pac.content_id
      SQL

      rummager_links_query = <<-SQL
      SELECT
        rl.link_type,
        link_lookup.content_id as link_content_id,
        lookup.content_id,
        pac.publishing_app,
        pac.format
      FROM rummager_link rl
      JOIN rummager_base_path_content_id lookup ON lookup.base_path = rl.base_path
      JOIN rummager_base_path_content_id link_lookup ON link_lookup.base_path = rl.link_base_path
      JOIN publishing_api_content pac ON lookup.content_id = pac.content_id
      SQL

      publishing_api_missing_links_query = "#{rummager_links_query} EXCEPT #{publishing_api_links_query}"

      name = self.class.name.split('::').last
      headers = ['link_type', 'link_content_id', 'content_id', 'publishing_app', 'format']
      publishing_api_missing_links = @whitelist.apply(name, headers, @checker_db.execute(publishing_api_missing_links_query))

      Report.create(name, headers, publishing_api_missing_links)
    end
  end
end
