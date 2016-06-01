module Checks
  class Reporter
    def initialize(whitelist)
      @whitelist = whitelist
    end

    def create_report(name, headers, candidate_rows)
      whitelist_function = @whitelist.get_whitelist_function(name, headers)
      rows = candidate_rows.reject(&whitelist_function)
      Checks::Report.new(
        name: name,
        success: rows.empty?,
        summary: "#{name} report: found #{rows.size}",
        csv: generate_csv(headers, rows),
        csv_including_whitelisted_rows: generate_csv(headers, candidate_rows),
      )
    end

    def report_expired_whitelist_entries
      headers = %w(check_name expiry_date reason)
      expiries = @whitelist.report_expired_entries(Date.today)
      create_report('ExpiredWhitelistEntries', headers, expiries)
    end

  private

    def generate_csv(headers, rows)
      CSV.generate do |csv|
        csv << headers
        rows.each { |row| csv << row }
      end
    end
  end


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
end
