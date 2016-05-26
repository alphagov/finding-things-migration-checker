require 'webmock/rspec'
require 'checker'
require 'fileutils'

# integration test with in-memory db, webmocked services, empty whitelist, real csvs (removed afterwards)
# TODO: suppress logging
RSpec.describe CheckRunner do
  before do
    @publishing_api_content_and_links_url = "#{Plek.new.find('publishing-api')}/v2/grouped_content_and_links"
    @publishing_api_lookup_url = "#{Plek.new.find('publishing-api')}/lookup-by-base-path"
    @rummager_search_url = "#{Plek.new.find('rummager')}/unified_search.json"

    @csvdir = tempdir

    stub_publishing_api_content_request(
      request_last_seen_content_id: '00000000-0000-0000-0000-000000000000',
      response_last_seen_content_id: '1',
      response_results: [],
    )

    stub_rummager_content_request(
      request_count: '0',
      response_total: 3,
      response_results: [],
    )

    stub_rummager_content_request(
      request_start: '0',
      response_total: 3,
      response_results: [],
    )
    # TODO: stub a real iteration
  end

  after do
    cleanup
  end

  it "runs imports, runs checks, and generates output" do
    runner = CheckRunner.new("CHECK_OUTPUT_DIR" => @csvdir, "SUPPRESS_PROGRESS" => "y")
    exit_code = runner.run
    expect(exit_code).to eq(0)

    check_csvs_are_present
  end

  def check_csvs_are_present
    expected_csvs = [
      'BasePathsMissingFromRummager.csv',
      'BasePathsMissingFromPublishingApi.csv',
      'LinkedBasePathsMissingFromPublishingApi.csv',
      'LinksMissingFromRummager.csv',
      'LinksMissingFromPublishingApi.csv',
      'RummagerLinksNotIndexedInRummager.csv',
      'ExpiredWhitelistEntries.csv',
    ]
    actual_csvs = Dir[File.join(@csvdir, '*')].map { |f| File.basename(f) }
    expect(actual_csvs).to contain_exactly(*expected_csvs)
  end

  def stub_publishing_api_content_request(request_last_seen_content_id:, response_last_seen_content_id:, response_results:)
    WebMock.stub_request(:get, @publishing_api_content_and_links_url)
      .with(query: hash_including("last_seen_content_id" => request_last_seen_content_id))
      .to_return(body: { last_seen_content_id: response_last_seen_content_id, results: response_results }.to_json)
  end

  def stub_rummager_content_request(request_count: nil, request_start: nil, response_total:, response_results:)
    query_hash = {}
    query_hash['count'] = request_count if request_count
    query_hash['start'] = request_start if request_start
    WebMock.stub_request(:get, @rummager_search_url)
      .with(query: hash_including(query_hash))
      .to_return(body: { total: response_total, results: response_results }.to_json)
  end

  def tempdir
    Dir.mktmpdir('finding_things_migration_checker_csvs_')
  end

  def cleanup
    FileUtils.rm_r @csvdir
  end
end
