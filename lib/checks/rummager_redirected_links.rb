module Checks
  class RummagerRedirectedLinks
    def initialize(name, checker_db, reporter)
      @name = name
      @checker_db = checker_db
      @reporter = reporter
    end

    def run_check
      query = <<-SQL
      SELECT
        rl.base_path as document_base_path,
        rl.link_type as link_type,
        link_lookup.content_id as link_content_id,
        link_lookup.base_path as link_base_path,
        pubapi_document.publishing_app as document_publishing_app

      FROM rummager_link rl

      JOIN rummager_base_path_content_id link_lookup
        ON link_lookup.base_path = rl.link_base_path

      JOIN publishing_api_content pubapi_link
        ON link_lookup.content_id = pubapi_link.content_id

      LEFT JOIN rummager_base_path_content_id document_lookup
        ON document_lookup.base_path = rl.base_path

      LEFT JOIN publishing_api_content pubapi_document
        ON document_lookup.content_id = pubapi_document.content_id

      WHERE pubapi_link.format = 'redirect'
      SQL

      headers = %w(
        document_base_path
        link_type
        link_content_id
        link_base_path
        document_publishing_app
      )

      rows = @checker_db.execute(query)
      @reporter.create_report(@name, headers, rows)
    end
  end
end
