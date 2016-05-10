require './lib/database'
require './lib/fetch_publishing_api_links'
require './lib/fetch_publishing_api_content'
require './lib/fetch_rummager'
require './lib/rummager_data_presenter'


class DataImporter
  def initialize
    @database = Database.new
  end

  def compare!
    @database.find_missing_topics_and_browse!(output: :csv)
  end

  def import_data_from_rummager
    create_rummager_table

    rummager = FetchRummager.new

    rummager.request_data! do |search_results|
      start = Time.now.to_f
      search_results.each do |search_result|
        rows = RummagerDataPresenter.new(search_result).present!

        rows.each do |row|
          @database.insert(table_name: 'rummager', row: row)
        end
      end
      duration = Time.now.to_f - start
      puts "batch insert took #{duration}"
    end
  end

  private

  def create_rummager_table
    puts "creating rummager table..."

    @database.create_table(
      table_name: "rummager",
      columns: [
        "base_path text",
        "link_type text",
        "link_base_paths text[]",
      ]
    )
  end
end
