module Checks
  class BasePathsMissingFromPublishingApi

    def initialize(checker_db)
      @checker_db = checker_db
      @missing_from_publishing_api = {}
    end

    # find content_ids for base_paths present in Rummager which
    # don't map to a published content item in the Publishing API

    def run_check
      # query = <<-SQL
      # SELECT DISTINCT base_path FROM rummager
      # EXCEPT
      # SELECT base_path FROM api_content
      # SQL
      #
      # results = @connection.exec(query)
      #
      # puts "UNMATCHED BASE PATHS"
      #
      # results.each_row do |row|
      #   puts row
      #   puts '------------------------------'
      # end
      #
      # puts "#{results.ntuples} unmatched base paths found"

    end

    def report
      'MissingFromPublishingApi report'
    end

    def failed?
      !@missing_from_publishing_api.empty?
    end
  end
end
