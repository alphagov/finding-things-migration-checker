module Checks
  class RummagerLinksNotIndexedInRummager

    def initialize(checker_db)
      @checker_db = checker_db
    end

    # find base_paths linked to from Rummager items which are not themselves indexed in Rummager
    # For example, in the past a removed organisation was correctly deindexed but was not removed from all link sets

    def run_check
      query = <<-SQL
      SELECT
      rl.link_base_path,
      rl.link_type,
      rl.base_path,
      rc_item.format,
      rc_item.rummager_index,
      rc_item.document_type
      FROM rummager_link rl
      LEFT JOIN rummager_content rc ON rc.base_path = rl.link_base_path
      JOIN rummager_content rc_item ON rc_item.base_path = rl.base_path
      WHERE rc.base_path IS NULL
      SQL

      links_not_indexed = @checker_db.execute(query)
      name = self.class.name.split('::').last
      Report.new(
          name: name,
          success: links_not_indexed.empty?,
          summary: "#{name} report: found #{links_not_indexed.size}",
          csv: CSV.generate do |csv|
            csv << ['link', 'link_type', 'item', 'item_format', 'item_index', 'item_document_type']
            links_not_indexed.each { |row| csv << row }
          end
      )
    end
  end
end
