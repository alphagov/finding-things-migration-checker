module Checks
  class LinksMissingFromPublishingApi
    def initialize(name, checker_db, reporter)
      @name = name
      @checker_db = checker_db
      @reporter = reporter
    end

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

      headers = %w(link_type link_content_id content_id publishing_app format)
      rows = @checker_db.execute(publishing_api_missing_links_query)
      @reporter.create_report(@name, headers, rows)
    end
  end
end
