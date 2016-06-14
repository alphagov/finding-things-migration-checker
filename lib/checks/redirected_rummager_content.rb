module Checks
  class RedirectedRummagerContent
    def initialize(name, checker_db, reporter)
      @name = name
      @checker_db = checker_db
      @reporter = reporter
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
      WHERE pac.schema_name = 'redirect'
      SQL

      headers = %w(content_id base_path publishing_app)
      rows = @checker_db.execute(query)
      @reporter.create_report(@name, headers, rows)
    end
  end
end
