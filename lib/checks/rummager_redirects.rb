module Checks
  class RummagerRedirects
    def initialize(name, checker_db, whitelist)
      @name = name
      @checker_db = checker_db
      @whitelist = whitelist
    end

    def run_check
      query = <<-SQL
      SELECT
        lookup.content_id,
        lookup.base_path,
        pac.publishing_app
      FROM rummager_link rl
      JOIN rummager_base_path_content_id lookup ON lookup.base_path = rl.base_path
      JOIN publishing_api_content pac ON lookup.content_id = pac.content_id
      WHERE pac.format = 'redirect'
      SQL

      headers = %w(content_id base_path publishing_app)
      results = @whitelist.apply(@name, headers, @checker_db.execute(query))

      Report.create(@name, headers, results)
    end
  end
end
