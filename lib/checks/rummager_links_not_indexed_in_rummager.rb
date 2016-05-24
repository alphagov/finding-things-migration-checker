module Checks
  class RummagerLinksNotIndexedInRummager

    def initialize(name, checker_db, whitelist)
      @name = name
      @checker_db = checker_db
      @whitelist = whitelist
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

      headers = ['link', 'link_type', 'item', 'item_format', 'item_index', 'item_document_type']
      links_not_indexed = @whitelist.apply(name, headers, @checker_db.execute(query))

      Report.create(name, headers, links_not_indexed)
    end
  end
end
