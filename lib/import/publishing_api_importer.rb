module Import
  class PublishingApiImporter

    def initialize(checker_db, progress_reporter, publishing_api_url)
      @checker_db = checker_db
      @thread_pool = Thread.pool(1)
      @publishing_api_url = publishing_api_url
      @progress_reporter = progress_reporter
    end

    def import
      create_publishing_api_tables

      import_publishing_api_batches do |batch_data|
        @thread_pool.process {
          import_content(batch_data.map { |content_id_data| Import::PublishingApiDataPresenter.present_content(content_id_data) })
          import_content_links(batch_data.flat_map { |content_id_data| Import::PublishingApiDataPresenter.present_links(content_id_data) })
        }
      end
      @progress_reporter.message('publishing api import', "waiting for #{@thread_pool.backlog} remaining tasks to complete")
      @thread_pool.shutdown
      @progress_reporter.message('publishing api import', 'finished')
    end

  private

    BATCH_SIZE = 1000
    NIL_UUID = '00000000-0000-0000-0000-000000000000'

    def create_publishing_api_tables
      @checker_db.create_table(
        table_name: 'publishing_api_content',
        columns: [
          'content_id text',
          'publishing_app text',
          'format text',
          'ever_published text',
        ],
        index: ['content_id'],
      )

      @checker_db.create_table(
        table_name: 'publishing_api_link',
        columns: [
          'content_id text',
          'link_type text',
          'link_content_id text',
        ],
        index: ['content_id'],
      )
    end

    def import_publishing_api_batches
      response = do_request(NIL_UUID)
      results = response["results"]

      # We currently don't have a way in the publishing api to get the expected count of content_ids.
      # We hardcode a guess just to make the progress reporting slightly nicer during development.
      expected_total = 602365

      @progress_reporter.report('publishing api import', expected_total, 0, 'just starting')

      running_total = results ? results.size : 0

      while results && results.size > 0 do
        running_total += results.size
        yield results
        @progress_reporter.report('publishing api import', expected_total, running_total, 'importing...')
        response = do_request(response['last_seen_content_id'])
        results = response["results"]
      end
    end

    def do_request(last_seen_content_id)
      url = "#{@publishing_api_url}?page_size=#{BATCH_SIZE}&last_seen_content_id=#{last_seen_content_id}"

      response = Unirest.get(url)
      if response.code != 200 || !response.body["results"]
        raise "bad response: #{response.code}\n#{response.raw_body}"
      end
      response.body
    end

    def import_content(row)
      @checker_db.insert_batch(
          table_name: 'publishing_api_content',
          column_names: ['content_id', 'publishing_app', 'format', 'ever_published'],
          rows: row
      )
    end

    def import_content_links(rows)
      @checker_db.insert_batch(
          table_name: 'publishing_api_link',
          column_names: ['content_id', 'link_type', 'link_content_id'],
          rows: rows
        )
    end

  end
end
