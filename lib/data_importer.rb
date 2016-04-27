require './lib/database'
require './lib/fetch_publishing_api_links'
require './lib/fetch_rummager'
require './lib/rummager_data_presenter'


class DataImporter
  def initialize
    @database = Database.new
  end

  def import_data_from_publishing_api
    create_publishing_api_table

    publishing_api = FetchPublishingApiLinks.new

    data = publishing_api.request_data!

    @database.copy_rows(table_name: 'publishing_api') do
      data.each_row do |row|
        @database.copy_row(row)
      end
    end
  end

  def import_data_from_rummager
    create_rummager_table

    rummager = FetchRummager.new

    rummager.request_data! do |search_results|
      search_results.each do |search_result|
        rows = RummagerDataPresenter.new(search_result).present!

        @database.copy_rows(table_name: 'rummager') do
          rows.each do |row|
            @database.copy_row(row)
          end
        end
      end
    end
  end

  private

  def create_publishing_api_table
    puts "creating publishing api table..."

    @database.create_table(
      table_name: 'publishing_api',
      columns: [
        'content_id text',
        'base_path text',
        'publishing_app text',
        'link_type text',
        'link_content_ids text',
        'link_base_paths text[]',
      ]
    )
  end

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
