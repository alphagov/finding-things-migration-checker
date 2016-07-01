module Checks
  class PublishingApiContentMissingFromRummager
    def initialize(name, checker_db, reporter)
      @name = name
      @checker_db = checker_db
      @reporter = reporter
    end

    def run_check
      query = <<-SQL
      SELECT
        pac.content_id,
        pac.publishing_app,
        pac.document_type,
        pac.schema_name
      FROM publishing_api_content pac
      LEFT JOIN rummager_base_path_content_id lookup ON pac.content_id = lookup.content_id
      WHERE lookup.base_path IS NULL
      AND pac.ever_published = 'published_at_least_once'
      SQL

      headers = %w(content_id publishing_app document_type schema_name)
      rows = @checker_db.execute(query)
      [@reporter.create_report(@name, headers, rows)]
    end
  end
end
