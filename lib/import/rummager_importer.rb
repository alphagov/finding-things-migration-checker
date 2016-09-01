module Import
  class RummagerImporter
    def initialize(checker_db, progress_reporter)
      @checker_db = checker_db
      @progress_reporter = progress_reporter
    end

    def import
      Tables.create_rummager_tables(@checker_db)

      import_rummager_batches do |batch_data|
        items = Import::RummagerDataPresenter.present_content(batch_data)
        import_content(items)
        import_base_path_mappings(items.map { |item| item[0] })
        import_rummager_links(batch_data)
      end

      @progress_reporter.message('rummager import', 'mapping remaining linked base_paths to content_ids')
      import_linked_base_path_mappings
      @progress_reporter.message('rummager import', 'adding indexes')
      Tables.create_rummager_indexes(@checker_db)
      @progress_reporter.message('rummager import', 'finished')
    end

  private

    BATCH_SIZE = 1000

    def import_rummager_batches
      offset = 0
      @progress_reporter.report('rummager import', 0, 'just starting')

      results = do_request(offset)

      while results && !results.empty? do
        yield results
        offset += results.size
        results = do_request(offset)
        @progress_reporter.report('rummager import', offset, 'importing...')
      end
    end

    def do_request(offset)
      Services.rummager.search(
        fields: %w(link content_id format is_withdrawn mainstream_browse_pages specialist_sectors organisations policy_groups people),
        order: 'public_timestamp',
        start: offset,
        count: BATCH_SIZE,
        debug: 'include_withdrawn'
      ).results
    end

    def import_content(rows)
      @checker_db.insert_batch(
        table_name: 'rummager_content',
        column_names: %w(base_path content_id format rummager_index is_withdrawn),
        rows: rows
      )
    end

    def import_base_path_mappings(base_paths)
      base_paths.compact.each_slice(200) do |batch|
        base_paths_to_content_ids = Services.publishing_api.lookup_content_ids(base_paths: batch)
        @checker_db.insert_batch(
          table_name: 'rummager_base_path_content_id',
          column_names: %w(base_path content_id),
          rows: base_paths_to_content_ids
        )
      end
    end

    def import_rummager_links(batch_data)
      link_data = batch_data.flat_map { |row_data| Import::RummagerDataPresenter.present_links(row_data) }
      @checker_db.insert_batch(
        table_name: 'rummager_link',
        column_names: %w(base_path link_type link_base_path),
        rows: link_data
      )
    end

    def import_linked_base_path_mappings
      query = <<-SQL
      SELECT
        rl.link_base_path
      FROM rummager_link rl
      LEFT JOIN rummager_base_path_content_id lookup ON lookup.base_path = rl.link_base_path
      WHERE lookup.content_id IS NULL
      SQL
      missing_links_base_paths = @checker_db.execute(query).flatten
      import_base_path_mappings(missing_links_base_paths)
    end
  end
end
