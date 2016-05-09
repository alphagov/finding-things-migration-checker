require './lib/database'
require './lib/fetch_publishing_api_links'
require './lib/fetch_publishing_api_content'
require './lib/fetch_rummager'
require './lib/rummager_data_presenter'


class DataImporter
  def initialize
    @database = Database.new
  end

  def import_links_from_publishing_api
    create_publishing_api_table

    publishing_api = FetchPublishingApiLinks.new

    data = publishing_api.request_data!

    data.each do |row|
      @database.insert(table_name: 'publishing_api', row: row)
    end
  end

  def import_content_from_publishing_api
    create_publishing_api_content_table

    publishing_api = FetchPublishingApiContent.new

    data = publishing_api.request_data!

    data.each do |row|
      @database.insert(table_name: 'api_content', row: row)
    end
  end

  def import_data_from_rummager
    create_rummager_table

    rummager = FetchRummager.new

    rummager.request_data! do |search_results|
      search_results.each do |search_result|
        rows = RummagerDataPresenter.new(search_result).present!

        rows.each do |row|
          @database.insert(table_name: 'rummager', row: row)
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

  def create_publishing_api_content_table
    puts "creating publishing api content table..."

    @database.create_table(
      table_name: 'api_content',
      columns: [
        'content_id text',
        'base_path text',
        'format text',
        'publishing_app text',
        'routes text',
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
