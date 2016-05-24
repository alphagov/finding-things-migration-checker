module Import
  class RummagerImporter

    def initialize(checker_db, progress_reporter)
      @checker_db = checker_db
      @thread_pool = Thread.pool(3)
      @progress_reporter = progress_reporter

      @rummager = GdsApi::Rummager.new(
        Plek.new.find('rummager'),
        timeout: 20,
      )
      @publishing_api = GdsApi::PublishingApiV2.new(
        Plek.new.find('publishing-api'),
        bearer_token: ENV['PUBLISHING_API_BEARER_TOKEN'] || 'example',
        timeout: 20,
      )
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
          index: ['base_path', 'content_id']
      )
    end

    def import_rummager_batches
      offset = 0
      expected_total_docs = get_total_document_count
      @progress_reporter.report('rummager import', expected_total_docs, 0, 'just starting')

      results = do_request(offset)

      while results && results.size > 0 do
        yield results
        offset += results.size
        results = do_request(offset)
        @progress_reporter.report('rummager import', expected_total_docs, offset, 'importing...')
      end
    end

    def do_request(offset)
      @rummager.unified_search(
          fields: [
              'link', 'content_id', 'format',
              'mainstream_browse_pages', 'specialist_sectors', 'organisations', 'policy_groups', 'people',
          ],
          start: offset,
          count: BATCH_SIZE,
      ).results
    end

    def import_content(rows)
      @checker_db.insert_batch(
          table_name: 'rummager_content',
          column_names: ['base_path', 'content_id', 'format', 'rummager_index', 'document_type'],
          rows: rows
      )
    end

    def import_base_path_mappings(base_paths)
      base_paths.each_slice(200) do |batch|
        base_paths_to_content_ids = @publishing_api.lookup_content_ids(base_paths: batch)
        @checker_db.insert_batch(
            table_name: 'rummager_base_path_content_id',
            column_names: ['base_path', 'content_id'],
            rows: base_paths_to_content_ids
        )
      end
    end

    def import_rummager_links(batch_data)
      link_data = batch_data.flat_map { |row_data| Import::RummagerDataPresenter.present_links(row_data) }
      @checker_db.insert_batch(
          table_name: 'rummager_link',
          column_names: ['base_path', 'link_type', 'link_base_path'],
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
      missing_links_base_path = @checker_db.execute(query)
      import_base_path_mappings(missing_links_base_path)
    end

    def get_total_document_count
      @rummager.unified_search(count: 0).total
    end
  end
end
