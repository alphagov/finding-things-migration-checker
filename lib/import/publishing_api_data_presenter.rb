module Import
  class PublishingApiDataPresenter

    private_class_method :initialize

    def self.present(content_id_data)

      links = parse_links(content_id_data)

      content_id = content_id_data['content_id']

      links.map { |link_arr| [content_id] + link_arr }
    end

    private

    def self.parse_links(content_id_data)
      content_id_data['links'].flat_map { |link_type| link_type[1].map { |link| [link_type[0], link] } }
    end

    def self.parse_base_paths(content_id_data)
      content_id_data['content_items'].map { |ci| ci["base_path"] }
    end
  end
end
