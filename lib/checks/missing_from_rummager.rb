module Checks
  class MissingFromRummager

    def initialize(checker_db)
      @checker_db = checker_db
    end

    # find content_ids present in Publishing API which have a published, not withdrawn content item
    # and for which no base_path is present in Rummager
    def run_check
      # query = <<-SQL
      # SELECT DISTINCT base_path FROM papi
      # EXCEPT
      # SELECT base_path FROM rummager
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

    class Report

      def initialize(missing_from_rummager)
        @missing_from_rummager = missing_from_rummager
      end

      def report
        'MissingFromRummager report'
      end

      def failed?
        !@missing_from_rummager.empty?
      end

    end
  end
end
