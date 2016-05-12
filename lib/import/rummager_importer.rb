module Import
  class RummagerImporter

    BATCH_SIZE = 1000

    def initialize(checker_db, progress_reporter)
      @checker_db = checker_db
      @progress_reporter = progress_reporter

      @rummager = GdsApi::Rummager.new(Plek.new.find('rummager'))
      @publishing_api = GdsApi::PublishingApiV2.new(
          Plek.new.find('publishing-api'),
          bearer_token: ENV['PUBLISHING_API_BEARER_TOKEN'] || 'example'
      )

    end

    def import
      create_rummager_tables

      import_rummager_batches do |batch_data|

        base_paths = Import::RummagerDataPresenter.present_base_paths(batch_data)
        base_paths_to_content_ids = @publishing_api.lookup_content_ids(base_paths: base_paths)
        if base_paths.size != base_paths_to_content_ids.size
          @progress_reporter.error('rummager import', "unexpected base path mapping size: #{base_paths_to_content_ids.size} for #{base_paths.size} base paths")
        end
        import_base_path_mappings(base_paths_to_content_ids)

        batch_data.each do |row_data|
          import_rummager_links(row_data)
        end
      end

      # TODO: look up all linked base_paths - but no need to look up those we already have

    end

  private

    def create_rummager_tables
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
      @progress_reporter.report('rummager import', expected_total_docs, offset, 'finished')
    end

    def do_request(offset)
      @rummager.unified_search(
          fields: ['link', 'mainstream_browse_pages', 'specialist_sectors', 'organisations', 'policy_groups', 'content_id'],
          start: offset,
          count: BATCH_SIZE,
      ).results
    end

    def import_base_path_mappings(base_paths_to_content_ids)
      base_paths_to_content_ids.each do |base_path_mapping|
        @checker_db.insert(
            table_name: 'rummager_base_path_content_id',
            column_names: ['base_path', 'content_id'],
            row: base_path_mapping
        )
      end
    end

    def import_rummager_links(row_data)
      rows = Import::RummagerDataPresenter.present(row_data)
      rows.each do |row|
        @checker_db.insert(
            table_name: 'rummager_link',
            column_names: ['base_path', 'link_type', 'link_base_path'],
            row: row
        )
      end
    end

    def get_total_document_count
      @rummager.unified_search(count: 0).total
    end

  end
end
