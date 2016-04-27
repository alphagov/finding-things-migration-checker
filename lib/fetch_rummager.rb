require 'unirest'
require 'active_support'
require 'active_support/core_ext/object/blank'

class FetchRummager
  BATCH_SIZE = 3500

  def initialize
    @endpoint = ENV["RUMMAGER_URL"] || 'http://rummager.dev.gov.uk/unified_search.json'
    @total_documents = Unirest.get("#{@endpoint}?count=0").body["total"]
    @num_pages = (@total_documents / BATCH_SIZE) + 1
  end

  def request_data!
    puts "found #{@total_documents} documents"
    puts "requesting rummager data..."

    @num_pages.times.each do |page|
      offset = page * BATCH_SIZE
      page_counter = (@num_pages - page)

      puts "pages to go: #{page_counter}"

      url = "#{@endpoint}?fields[]=link&fields[]=mainstream_browse_pages" \
            "&fields[]=specialist_sectors&fields[]=organisations" \
            "&fields[]=policy_groups&fields[]=content_id&count=#{BATCH_SIZE}&start=#{offset}"

      yield Unirest.get(url).body["results"]
    end
  end
end
