require 'webmock/rspec'
require 'checker'

RSpec.describe Services do
  it "retry requests when the first attempt times out" do
    @publishing_api_content_and_links_url = "#{Plek.new.find('publishing-api')}/v2/grouped-content-and-links"

    WebMock.stub_request(:get, @publishing_api_content_and_links_url)
      .to_raise(Timeout::Error)
      .then
      .to_return(body: '{ "foo": "foo" }')

    expect(Services.publishing_api.get_grouped_content_and_links["foo"]).to eq 'foo'
  end
end
