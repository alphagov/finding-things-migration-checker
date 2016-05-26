module Checks
  class LinkedBasePathsMissingFromPublishingApi
    def initialize(name, checker_db, whitelist)
      @name = name
      @checker_db = checker_db
      @whitelist = whitelist
    end

    def run_check
      query = <<-SQL
      SELECT
        rl.link_base_path,
        rl.link_type,
        rl.base_path,
        rc.format,
        rc.rummager_index,
        rc.document_type
      FROM rummager_link rl
      LEFT JOIN rummager_base_path_content_id lookup ON rl.link_base_path = lookup.base_path
      JOIN rummager_content rc ON rc.base_path = rl.base_path
      WHERE lookup.content_id IS NULL
      SQL

      headers = %w(link link_type item item_format item_index item_document_type)
      missing_from_publishing_api = @whitelist.apply(@name, headers, @checker_db.execute(query))

      Report.create(@name, headers, missing_from_publishing_api)
    end
  end
end
