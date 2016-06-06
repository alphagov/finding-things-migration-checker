module Import
  module RummagerDataPresenter
    def self.present_content(batch_data)
      batch_data.map do |item|
        [
          item['link'],
          item['content_id'],
          item['format'],
          item['index'],
        ]
      end
    end

    def self.present_links(row_data)
      base_path     = row_data["link"]

      organisations = fetch_resources(row_data, "organisations", "/government/organisations/")
      people        = fetch_resources(row_data, "people", "/government/people/")
      policies      = fetch_resources(row_data, "policies")
      policy_groups = fetch_resources(row_data, "policy_groups", '/government/groups/')
      specialist_sectors = fetch_resources(row_data, "specialist_sectors", "/topic/")
      mainstream_browse_pages = fetch_resources(row_data, "mainstream_browse_pages", "/browse/")

      rows_for(base_path, 'policies', policies) +
        rows_for(base_path, 'people', people) +
        rows_for(base_path, 'organisations', organisations) +
        rows_for(base_path, 'working_groups', policy_groups) +
        rows_for(base_path, 'topics', specialist_sectors) +
        rows_for(base_path, 'mainstream_browse_pages', mainstream_browse_pages)
    end

    def self.fetch_resources(row_data, resource_name, prefix = "")
      resources = row_data[resource_name]
      return nil unless resources

      resources.map do |resource|
        case resource
        when String
          prefix + resource
        else
          resource['link']
        end
      end
    end

    def self.rows_for(base_path, link_type, links)
      links ? links.map { |link| [base_path, link_type, link] } : []
    end

    private_class_method :fetch_resources, :rows_for
  end
end
