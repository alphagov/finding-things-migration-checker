module Checks
  class BasePathsMissingFromPublishingApi

    def initialize(checker_db)
      @checker_db = checker_db
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

      missing_from_publishing_api = @checker_db.execute(query)
      name = self.class.name.split('::').last
      Report.new(
          name: name,
          success: missing_from_publishing_api.empty?,
          summary: "#{name} report: found #{missing_from_publishing_api.size}",
          csv: CSV.generate do |csv|
            csv << ['base_path', 'format', 'index', 'document_type']
            missing_from_publishing_api.each { |row| csv << row }
          end
      )
    end
  end
end
