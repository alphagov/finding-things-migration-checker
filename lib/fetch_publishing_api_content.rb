class FetchPublishingApiContent

  def initialize
    @connection = PG.connect(ENV["DATABASE_URL"] || 'postgresql:///publishing_api_development')
  end

  def request_data!
    query = <<-QUERY
    SELECT
      content.content_id,
      locations.base_path,
      content.format,
      content.publishing_app,
      (content.routes)->0->>'path'
    FROM
      content_items content
      join states on states.content_item_id = content.id and states.name='published'
      join locations on locations.content_item_id = content.id
      join translations on translations.content_item_id = content.id and translations.locale = 'en'
    QUERY

    @connection.exec(query)
  end
end
