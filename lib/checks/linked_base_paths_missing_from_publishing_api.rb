module Checks
  class LinkedBasePathsMissingFromPublishingApi

    def initialize(checker_db)
      @checker_db = checker_db
    end

    # find content_ids for base_paths present in links in Rummager which
    # don't map to a published content item in the Publishing API

    def run_check

      query = <<-SQL
      SELECT
      rl.linked_base_path
      FROM rummager_links rl
      LEFT JOIN ruwmmager_base_path_content_id lookup ON rl.linked_base_path = lookup.base_path
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
        'LinkedBasePathsMissingFromPublishingApi report'
      end

      def failed?
        !@missing_from_publishing_api.empty?
      end

    end
  end
end
