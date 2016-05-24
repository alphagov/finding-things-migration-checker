module Checks
  class BasePathsMissingFromPublishingApi

    def initialize(name, checker_db, whitelist)
      @name = name
      @checker_db = checker_db
      @whitelist = whitelist
    end

    # find base_paths present in Rummager which don't map to a published content item in the Publishing API

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

      headers = ['base_path', 'format', 'index', 'document_type']
      missing_from_publishing_api = @whitelist.apply(name, headers, @checker_db.execute(query))

      Report.create(name, headers, missing_from_publishing_api)
    end
  end
end
