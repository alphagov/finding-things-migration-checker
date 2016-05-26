module Checks
  class BasePathsMissingFromRummager
    def initialize(name, checker_db, whitelist)
      @name = name
      @checker_db = checker_db
      @whitelist = whitelist
    end

    def run_check
      query = <<-SQL
      SELECT
        pac.content_id,
        pac.publishing_app,
        pac.format
      FROM publishing_api_content pac
      LEFT JOIN rummager_base_path_content_id lookup ON pac.content_id = lookup.content_id
      WHERE lookup.base_path IS NULL
      AND pac.ever_published = 'published_at_least_once'
      SQL

      headers = %w(content_id publishing_app format)
      missing_from_rummager = @whitelist.apply(@name, headers, @checker_db.execute(query))

      Report.create(@name, headers, missing_from_rummager)
    end
  end
end
