module Checks
  class LinkedBasePathsMissingFromPublishingApi

    def initialize(checker_db)
      @checker_db = checker_db
    end

    # find content_ids for base_paths present in links in Rummager which
    # don't map to a published content item in the Publishing API

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

      missing_from_publishing_api = @checker_db.execute(query)
      name = self.class.name.split('::').last
      Report.new(
          name: name,
          success: missing_from_publishing_api.empty?,
          summary: "#{name} report: found #{missing_from_publishing_api.size}",
          csv: CSV.generate do |csv|
            csv << ['link', 'link_type', 'item', 'item_format', 'item_index', 'item_document_type']
            missing_from_publishing_api.each { |row| csv << row }
          end
      )
    end
  end
end
