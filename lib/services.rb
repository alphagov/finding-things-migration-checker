module Services
  def self.publishing_api
    @publishing_api ||= GdsApi::PublishingApiV2.new(
      Plek.new.find('publishing-api'),
      bearer_token: ENV['PUBLISHING_API_BEARER_TOKEN'] || 'example',
      timeout: 20,
    )
  end

  def self.rummager
    @rummager ||= GdsApi::Rummager.new(
      Plek.new.find('rummager'),
      timeout: 20,
    )
  end
end

# This will move to gds-api-adapters once we have a generalised use case.
class GdsApi::PublishingApiV2
  def get_grouped_content_and_links(last_seen_content_id: nil, page_size: nil)
    params = {}
    params["last_seen_content_id"] = last_seen_content_id unless last_seen_content_id.nil?
    params["page_size"] = page_size unless page_size.nil?

    query = query_string(params)

    get_json!("#{endpoint}/v2/grouped-content-and-links#{query}")
  end
end
