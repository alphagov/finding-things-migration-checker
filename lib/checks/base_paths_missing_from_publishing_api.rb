module Checks
  class BasePathsMissingFromPublishingApi

    def initialize(checker_db)
      @checker_db = checker_db
    end

    # find content_ids for base_paths present in Rummager which
    # don't map to a published content item in the Publishing API

    def run_check
      query = <<-SQL
      SELECT
      rc.base_path
      FROM rummager_content rc
      LEFT JOIN rummager_base_path_content_id lookup ON rc.base_path = lookup.base_path
      WHERE lookup.content_id IS NULL
      SQL

      Report.new(@checker_db.execute(query))
    end

    class Report

      def initialize(missing_from_publishing_api)
        @missing_from_publishing_api = missing_from_publishing_api
      end

      def report
        p @missing_from_publishing_api
        'BasePathsMissingFromPublishingApi report'
      end

      def failed?
        !@missing_from_publishing_api.empty?
      end

    end
  end
end
