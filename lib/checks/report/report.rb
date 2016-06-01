module Checks
  module Report
    class Report
      attr_reader :name, :success, :summary, :csv, :csv_including_whitelisted_rows

      private_class_method :initialize

      def initialize(name:, success:, summary:, csv:, csv_including_whitelisted_rows:)
        @name = name
        @success = success
        @summary = summary
        @csv = csv
        @csv_including_whitelisted_rows = csv_including_whitelisted_rows
      end
    end

    def self.create(name, headers, candidate_rows, whitelist_function)
      rows = candidate_rows.reject(&whitelist_function)
      Checks::Report::Report.new(
        name: name,
        success: rows.empty?,
        summary: "#{name} report: found #{rows.size}",
        csv: generate_csv(headers, rows),
        csv_including_whitelisted_rows: generate_csv(headers, candidate_rows),
      )
    end

    def self.generate_csv(headers, rows)
      CSV.generate do |csv|
        csv << headers
        rows.each { |row| csv << row }
      end
    end
  end
end
