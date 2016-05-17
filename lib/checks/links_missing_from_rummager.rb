module Checks
  class LinksMissingFromRummager

    def initialize(checker_db)
      @checker_db = checker_db
    end

    # find links present in Publishing API which are not present in Rummager

    def run_check
      publishing_api_links_query = <<-SQL
      SELECT
        pal.link_type,
        pal.link_content_id,
        pal.content_id,
        pac.publishing_app,
        pac.format
      FROM publishing_api_link pal
      JOIN publishing_api_content pac ON pal.content_id = pac.content_id
      WHERE pal.link_type IN ('people', 'organisations', 'working_groups', 'topics', 'mainstream_browse_pages')
      AND pac.ever_published = 'published_at_least_once'
      SQL

      rummager_links_query = <<-SQL
      SELECT
        rl.link_type,
        link_lookup.content_id as link_content_id,
        lookup.content_id,
        pac.publishing_app,
        pac.format
      FROM rummager_link rl
      JOIN rummager_base_path_content_id lookup ON lookup.base_path = rl.base_path
      JOIN rummager_base_path_content_id link_lookup ON link_lookup.base_path = rl.link_base_path
      JOIN publishing_api_content pac ON lookup.content_id = pac.content_id
      SQL

      rummager_missing_links_query = "#{publishing_api_links_query} EXCEPT #{rummager_links_query}"
      rummager_missing_links = @checker_db.execute(rummager_missing_links_query)

      # TODO figure out why we get some null rows?

      name = self.class.name.split('::').last
      Report.new(
          name: name,
          success: rummager_missing_links.empty?,
          summary: "#{name} report: found #{rummager_missing_links.size}",
          csv: CSV.generate do |csv|
            csv << ['link_type', 'link_content_id', 'content_id', 'publishing_app', 'format']
            rummager_missing_links.each { |row| csv << row }
          end
      )
    end
  end
end
