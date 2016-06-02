module Checks
  class BasePathsMissingFromPublishingApi
    def initialize(name, checker_db, reporter)
      @name = name
      @checker_db = checker_db
      @reporter = reporter
    end

    def run_check
      query = <<-SQL
      SELECT
        rc.base_path,
        rc.format,
        rc.rummager_index,
        rc.document_type
      FROM rummager_content rc
      LEFT JOIN rummager_base_path_content_id lookup ON rc.base_path = lookup.base_path
      WHERE lookup.content_id IS NULL
      AND format NOT IN ('recommended-link')
      SQL

      headers = %w(base_path format index document_type)
      rows = @checker_db.execute(query)
      @reporter.create_report(@name, headers, rows)
    end
  end
end
