module Checks
  class MismatchedLinks

    def initialize(checker_db)
      @checker_db = checker_db
    end

    # find content_ids present in both Rummager and Publishing API
    # which have differing links across the two systems.
    def run_check


      # query = <<-SQL
      # SELECT
      #   publishing_api.base_path,
      #   publishing_api.publishing_app,
      #   rummager.link_base_paths,
      #   publishing_api.link_base_paths
      # FROM publishing_api
      # JOIN rummager using(base_path, link_type)
      # WHERE publishing_api.link_base_paths <> rummager.link_base_paths
      # SQL
      #
      # results = @connection.exec(query)
      # results.each_row do |row|
      #   puts row
      #   puts '------------------------------'
      # end
      #
      # puts "#{results.ntuples} mismatches found"

    end

    class Report

      def initialize(differing_links)
        @differing_links = differing_links
      end

      def report
        'MismatchedLinks report'
      end

      def failed?
        !@differing_links.empty?
      end

    end
  end
end
