require 'webmock/rspec'
require 'checker'
require 'fileutils'

# integration test with in-memory db, webmocked services, empty whitelist, real csvs (removed afterwards)
RSpec.describe CheckRunner do
  before do
    @publishing_api_content_and_links_url = "#{Plek.new.find('publishing-api')}/v2/grouped-content-and-links"
    @publishing_api_lookup_url = "#{Plek.new.find('publishing-api')}/lookup-by-base-path"
    @rummager_search_url = "#{Plek.new.find('rummager')}/unified_search.json"

    @tempdir = tempdir
    @csvdir = File.join(@tempdir, 'csvs')
    Dir.mkdir(@csvdir)
    @whitelist = File.join(@tempdir, 'whitelist.yml')
    FileUtils.touch(@whitelist)

    stub_publishing_api_content
    stub_rummager_content
  end

  after do
    cleanup
  end

  it "runs imports, runs checks, and generates output" do
    runner = CheckRunner.new("CHECK_OUTPUT_DIR" => @csvdir, "SUPPRESS_PROGRESS" => "y", "WHITELIST_FILE" => @whitelist)

    exit_code = runner.run
    expect(exit_code).to eq(1)

    check_csvs_are_present

    check_csv_content
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
      'RummagerRedirectedLinks.csv',
      'RummagerRedirects.csv',
    ]
    actual_csvs = Dir[File.join(@csvdir, '*')].map { |f| File.basename(f) }
    expect(actual_csvs).to contain_exactly(*expected_csvs)
  end

  def check_csv_content
    expect(read_csv('LinksMissingFromRummager.csv')).to eq("link_type,link_content_id,content_id,publishing_app,format\norganisations,42,1,app1,format1\n")
    expect(read_csv('BasePathsMissingFromRummager.csv')).to eq("content_id,publishing_app,format\n1,app1,format1\n")
  end

  def read_csv(csv_filename)
    File.read(File.join(@csvdir, csv_filename))
  end

  def stub_publishing_api_content
    # first request, starting from the nil uuid
    stub_publishing_api_content_request(
      request_last_seen_content_id: '00000000-0000-0000-0000-000000000000',
      response_last_seen_content_id: '1',
      response_results: [
        {
          content_id: '1',
          content_items: [
            {
              locale: "en",
              base_path: "/base_path_1",
              publishing_app: "app1",
              format: "format1",
              user_facing_version: "3",
              state: "published"
            }],
          links: {
            organisations: ["42"],
            manual: ["84"]
          }
        }
      ]
    )

    # request starting from previous last_seen_content_id
    stub_publishing_api_content_request(
      request_last_seen_content_id: '1',
      response_last_seen_content_id: nil,
      response_results: []
    )
  end

  def stub_publishing_api_content_request(request_last_seen_content_id:, response_last_seen_content_id:, response_results:)
    WebMock.stub_request(:get, @publishing_api_content_and_links_url)
      .with(query: hash_including("last_seen_content_id" => request_last_seen_content_id))
      .to_return(body: { last_seen_content_id: response_last_seen_content_id, results: response_results }.to_json)
  end

  def stub_rummager_content
    # request the available total: one item
    stub_rummager_content_request(
      request_count: '0',
      response_total: 1,
      response_results: [],
    )

    # first request, get one item
    stub_rummager_content_request(
      request_start: '0',
      response_total: 1,
      response_results: [
        {
          format: "format2",
          link: "/base_path_2",
          organisations: [
            {
              link: "/link1"
            },
            {
              link: "/link2"
            }
          ],
          specialist_sectors: [
            {
              link: "/link3"
            }
          ],
          index: "mainstream",
          document_type: "edition"
        }
      ]
    )

    # content id lookup requests
    stub_publishing_api_lookup_request(request_base_paths: ['/base_path_2'], response_hash: { '/base_path_2' => '101' })
    stub_publishing_api_lookup_request(request_base_paths: ['/link1', '/link2', '/link3'], response_hash: { '/link1' => '1001', '/link3' => '1003' })

    #final request, nothing left
    stub_rummager_content_request(
      request_start: '1',
      response_total: 1,
      response_results: [],
    )
  end

  def stub_rummager_content_request(request_count: nil, request_start: nil, response_total:, response_results:)
    query_hash = {}
    query_hash['count'] = request_count if request_count
    query_hash['start'] = request_start if request_start
    WebMock.stub_request(:get, @rummager_search_url)
      .with(query: hash_including(query_hash))
      .to_return(body: { total: response_total, results: response_results }.to_json)
  end

  def stub_publishing_api_lookup_request(request_base_paths:, response_hash:)
    WebMock.stub_request(:post, @publishing_api_lookup_url)
      .with(body: hash_including("base_paths" => request_base_paths))
      .to_return(body: response_hash.to_json)
  end

  def tempdir
    Dir.mktmpdir('finding_things_migration_checker_csvs_')
  end

  def cleanup
    FileUtils.rm_r @csvdir
  end
end
