module Import
  class PublishingApiImporter

    def initialize(checker_db, progress_reporter, publishing_api_url)
      @checker_db = checker_db
      @publishing_api_url = publishing_api_url
      @progress_reporter = progress_reporter
    end

    def import
      create_publishing_api_tables

      import_publishing_api_batches do |batch_data|
        batch_data.each do |content_id_data|
          import_content_id_data(content_id_data)
        end
      end
    end

    private

    BATCH_SIZE = 1000
    NIL_UUID = '00000000-0000-0000-0000-000000000000'

    def create_publishing_api_tables
      @checker_db.create_table(
          table_name: "publishing_api_link",
          columns: [
              "content_id text",
              "link_type text",
              "link_content_id text",
          ],
          index: ['content_id'],
      )
    end

    def import_publishing_api_batches
      response = do_request(NIL_UUID)
      results = response["results"]

      # todo: can we get this for real? needs a new endpoint... probably not worth it. just supply a different progress reporter?
      expected_total = 500000

      @progress_reporter.report('publishing api import', expected_total, 0, 'just starting')

      running_total = results ? results.size : 0

      while results && results.size > 0 do
        running_total += results.size
        yield results
        @progress_reporter.report('publishing api import', expected_total, running_total, 'importing...')
        response = do_request(response['last_seen_content_id'])
        results = response["results"]
      end

      @progress_reporter.report('publishing api import', expected_total, running_total, 'finished')
    end

    def do_request(last_seen_content_id)
      url = "#{@publishing_api_url}?page_size=#{BATCH_SIZE}&last_seen_content_id=#{last_seen_content_id}"

      response = Unirest.get(url)
      if response.code != 200 || !response.body["results"]
        raise "bad response: #{response.code}\n#{response.raw_body}"
      end
      response.body
    end

    def import_content_id_data(content_id_data)
      rows = Import::PublishingApiDataPresenter.present(content_id_data)
      rows.each do |row|
        @checker_db.insert(
            table_name: 'publishing_api_link',
            column_names: ['content_id', 'link_type', 'link_content_id'],
            row: row
        )
      end
    end

  end
end
