require 'unirest'
require 'active_support'
require 'active_support/core_ext/object/blank'

class FetchRummager
  BATCH_SIZE = 1000

  def initialize
    @endpoint = ENV["RUMMAGER_URL"] || 'http://rummager.dev.gov.uk/unified_search.json'
    @total_documents = Unirest.get("#{@endpoint}?count=0").body["total"]
  end

  def request_data!
    puts "found #{@total_documents} documents"
    puts "requesting rummager data..."

    offset = 0
    results = do_request(offset)

    while (results.size > 0) do
      yield results
      offset += results.size
      puts "docs to go: #{@total_documents - offset}"

      results = do_request(offset)
    end
  end

  def do_request(offset)
    start = Time.now.to_f
    url = "#{@endpoint}?fields[]=link&fields[]=mainstream_browse_pages" \
          "&fields[]=specialist_sectors&fields[]=organisations" \
          "&fields[]=policy_groups&fields[]=content_id&count=#{BATCH_SIZE}&start=#{offset}"

    results = Unirest.get(url).body["results"]
    duration = Time.now.to_f - start
    puts "batch request took #{duration}"
    results
  end
end
