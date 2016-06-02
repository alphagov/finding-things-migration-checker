module Import
  class RummagerImporter
    def initialize(checker_db, progress_reporter)
      @checker_db = checker_db
      @thread_pool = Thread.pool(3)
      @progress_reporter = progress_reporter
    end

    def import
      create_rummager_tables

      import_rummager_batches do |batch_data|
        @thread_pool.process {
          items = Import::RummagerDataPresenter.present_content(batch_data)
          import_content(items)
          import_base_path_mappings(items.map { |item| item[0] })
        }
        # we do this on the main import thread to provide a little backoff - requests can time out in the dev vm otherwise
        import_rummager_links(batch_data)
      end

      import_linked_base_path_mappings

      @progress_reporter.message('rummager import', "waiting for #{@thread_pool.backlog} remaining tasks to complete")
      @thread_pool.shutdown
      @progress_reporter.message('rummager import', 'finished')
    end

  private

    BATCH_SIZE = 1000

    def create_rummager_tables
      @checker_db.create_table(
        table_name: "rummager_content",
        columns: [
          'base_path text',
          'content_id text',
          'format text',
          'rummager_index text',
          'document_type text',
        ],
        index: ['base_path']
      )

      @checker_db.create_table(
        table_name: "rummager_link",
        columns: [
          "base_path text",
          "link_type text",
          "link_base_path text",
        ],
        index: ['base_path']
      )

      @checker_db.create_table(
        table_name: "rummager_base_path_content_id",
        columns: [
          "base_path text",
          "content_id text",
        ],
        index: %w(base_path content_id)
      )
    end

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
      Services.rummager.unified_search(
        fields: %w(link content_id format mainstream_browse_pages specialist_sectors organisations policy_groups people),
        start: offset,
        count: BATCH_SIZE,
      ).results
    end

    def import_content(rows)
      @checker_db.insert_batch(
        table_name: 'rummager_content',
        column_names: %w(base_path content_id format rummager_index document_type),
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
