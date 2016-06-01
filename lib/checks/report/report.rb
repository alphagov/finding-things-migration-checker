module Checks
  module Report
    class Report
      attr_reader :name, :success, :summary, :csv

      private_class_method :initialize

      def initialize(name:, success:, summary:, csv:)
        @name = name
        @success = success
        @summary = summary
        @csv = csv
      end
    end

    def self.create(name, headers, rows)
      Checks::Report::Report.new(
        name: name,
        success: rows.empty?,
        summary: "#{name} report: found #{rows.size}",
        csv: CSV.generate do |csv|
          csv << headers
          rows.each { |row| csv << row }
        end
      )
    end
  end
end
