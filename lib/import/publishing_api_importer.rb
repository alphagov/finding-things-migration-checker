module Import
  class PublishingApiImporter
    def initialize(checker_db, progress_reporter)
      @checker_db = checker_db
      @progress_reporter = progress_reporter
    end

    def import
      create_publishing_api_tables

      import_publishing_api_batches do |batch_data|
        import_content(batch_data.map { |content_id_data| Import::PublishingApiDataPresenter.present_content(content_id_data) })
        import_content_links(batch_data.flat_map { |content_id_data| Import::PublishingApiDataPresenter.present_links(content_id_data) })
      end

      @progress_reporter.message('publishing api import', 'adding indexes')
      create_publishing_api_indexes
      @progress_reporter.message('publishing api import', 'finished')
    end

  private

    BATCH_SIZE = 1000
    NIL_UUID = '00000000-0000-0000-0000-000000000000'.freeze

    def create_publishing_api_tables
      @checker_db.create_table(
        table_name: 'publishing_api_content',
        columns: [
          'content_id text',
          'publishing_app text',
          'document_type text',
          'schema_name text',
          'ever_published text',
        ],
      )

      @checker_db.create_table(
        table_name: 'publishing_api_link',
        columns: [
          'content_id text',
          'link_type text',
          'link_content_id text',
        ],
      )
    end

    def create_publishing_api_indexes
      @checker_db.create_indexes(
        table_name: "publishing_api_content",
        index: %w(content_id),
      )

      @checker_db.create_indexes(
        table_name: "publishing_api_link",
        index: %w(content_id link_content_id),
      )
    end

    def import_publishing_api_batches
      @progress_reporter.report('publishing api import', 0, 'just starting')

      running_total = 0
      response = do_request(NIL_UUID)
      results = response["results"]

      while results && !results.empty? do
        running_total += results.size
        yield results
        @progress_reporter.report('publishing api import', running_total, 'importing...')
        response = do_request(response['last_seen_content_id'])
        results = response["results"]
      end
    end

    def do_request(last_seen_content_id)
      Services.publishing_api.get_grouped_content_and_links(
        last_seen_content_id: last_seen_content_id,
        page_size: BATCH_SIZE
      )
    end

    def import_content(row)
      @checker_db.insert_batch(
        table_name: 'publishing_api_content',
        column_names: %w(content_id publishing_app document_type schema_name ever_published),
        rows: row
      )
    end

    def import_content_links(rows)
      @checker_db.insert_batch(
        table_name: 'publishing_api_link',
        column_names: %w(content_id link_type link_content_id),
        rows: rows
      )
    end
  end
end
