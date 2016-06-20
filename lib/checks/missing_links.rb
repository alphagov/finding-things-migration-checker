module Checks
  class MissingLinks
    def initialize(name, checker_db, reporter)
      @name = name
      @checker_db = checker_db
      @reporter = reporter
    end

    def run_check
      # we're only interested in links on items for which we can connect the rummager data with the publishing-api data
      # in particular, links on missing items are not reported

      by_base_path_lookup, by_content_id_lookup = build_lookup_hashes

      rummager_links = find_rummager_links.select { |link| by_base_path_lookup.has_key? link.base_path }
      publishing_api_links = find_publishing_api_links.select { |link| by_content_id_lookup.has_key? link.content_id }

      enhance_links_with_missing_fields(rummager_links, publishing_api_links, by_base_path_lookup, by_content_id_lookup)

      rummager_links_arr = rummager_links.map(&:to_a)
      publishing_api_links_arr = publishing_api_links.map(&:to_a)

      missing_from_rummager = publishing_api_links_arr - rummager_links_arr
      missing_from_publishing_api = rummager_links_arr - publishing_api_links_arr

      headers = %w(link_type link_content_id link_base_path content_id base_path publishing_app document_type schema_name)

      [
        @reporter.create_report("LinksMissingFromRummager", headers, missing_from_rummager),
        @reporter.create_report("LinksMissingFromPublishingApi", headers, missing_from_publishing_api)
      ]
    end

    def enhance_links_with_missing_fields(rummager_links, publishing_api_links, by_base_path_lookup, by_content_id_lookup)
      rummager_links.each do |link|
        link.add_fields(
          link_content_id: by_base_path_lookup[link.link_base_path],
          content_id: by_base_path_lookup[link.base_path],
        )
      end
      publishing_api_links.each do |link|
        link.add_fields(
          link_base_path: by_content_id_lookup[link.link_content_id],
          base_path: by_content_id_lookup[link.content_id],
        )
      end
    end

    def build_lookup_hashes
      items_in_both_query = <<-SQL
      SELECT
        base_path,
        content_id
      FROM rummager_base_path_content_id
      SQL
      items_in_both_rows = @checker_db.execute(items_in_both_query)
      items_in_both_rows.reduce([{}, {}]) do |(by_base_path_lookup, by_content_id_lookup), (base_path, content_id)|
        by_base_path_lookup[base_path] = content_id
        by_content_id_lookup[content_id] = base_path
        [by_base_path_lookup, by_content_id_lookup]
      end
    end

    def find_publishing_api_links
      publishing_api_links_query = <<-SQL
      SELECT
        pal.link_type,
        pal.link_content_id,
        pal.content_id,
        pac.publishing_app,
        pac.document_type,
        pac.schema_name
      FROM publishing_api_link pal
      JOIN publishing_api_content pac ON pal.content_id = pac.content_id
      WHERE pal.link_type IN ('people', 'organisations', 'working_groups', 'topics', 'mainstream_browse_pages')
      AND pac.ever_published = 'published_at_least_once'
      SQL
      rows = @checker_db.execute(publishing_api_links_query)
      rows.map { |row| Link.publishing_api_link(row) }
    end

    def find_rummager_links
      rummager_links_query = <<-SQL
      SELECT
        rl.link_type,
        rl.link_base_path,
        rl.base_path,
        pac.publishing_app,
        pac.document_type,
        pac.schema_name
      FROM rummager_link rl
      LEFT JOIN rummager_base_path_content_id lookup ON lookup.base_path = rl.base_path
      LEFT JOIN publishing_api_content pac ON lookup.content_id = pac.content_id
      SQL
      rows = @checker_db.execute(rummager_links_query)
      rows.map { |row| Link.rummager_link(row) }
    end

    class Link
      attr_reader :link_content_id, :link_base_path, :content_id, :base_path

      private_class_method :new

      def initialize(
        link_type:, publishing_app:, document_type:, schema_name:,
        link_content_id: nil, link_base_path: nil, content_id: nil, base_path: nil
      )
        @link_type = link_type
        @link_content_id = link_content_id
        @link_base_path = link_base_path
        @content_id = content_id
        @base_path = base_path
        @publishing_app = publishing_app
        @document_type = document_type
        @schema_name = schema_name
      end

      def self.publishing_api_link(row)
        new(
          link_type: row[0],
          link_content_id: row[1],
          content_id: row[2],
          publishing_app: row[3],
          document_type: row[4],
          schema_name: row[5],
        )
      end

      def self.rummager_link(row)
        new(
          link_type: row[0],
          link_base_path: row[1],
          base_path: row[2],
          publishing_app: row[3],
          document_type: row[4],
          schema_name: row[5],
        )
      end

      def add_fields(link_base_path: nil, base_path: nil, link_content_id: nil, content_id: nil)
        @link_base_path ||= link_base_path
        @base_path ||= base_path
        @link_content_id ||= link_content_id
        @content_id ||= content_id
      end

      def to_a
        [
          @link_type,
          @link_content_id,
          @link_base_path,
          @content_id,
          @base_path,
          @publishing_app,
          @document_type,
          @schema_name,
        ]
      end
    end
  end
end
