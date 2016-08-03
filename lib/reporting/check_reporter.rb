module Reporting
  class CheckReporter
    def initialize(whitelist)
      @whitelist = whitelist
    end

    def create_report(name, headers, candidate_rows)
      whitelister = @whitelist.get_whitelister(name, headers)
      rows = reject(candidate_rows, whitelister)
      unused_whitelist_entries = whitelister.unused_entries
      Reporting::Report.new(
        name: name,
        success: rows.empty?,
        summary: "#{name} report: found #{rows.size} (#{candidate_rows.size - rows.size} whitelisted)",
        csv: generate_csv(headers, rows),
        csv_including_whitelisted_rows: generate_csv(headers, candidate_rows),
        unused_whitelist_entries: unused_whitelist_entries,
      )
    end

    def report_expired_whitelist_entries
      headers = %w(check_name expiry_date reason)
      expiries = @whitelist.report_expired_entries(Date.today)
      create_report('ExpiredWhitelistEntries', headers, expiries)
    end

  private

    def reject(rows, whitelister)
      selected = []

      rows.each do |row|
        begin
          selected << row if !whitelister.whitelist_function.call(row)
        rescue StandardError => e
          $stderr.puts "Error during processing: #{$!}"
          $stderr.puts "Backtrace:\n\t#{e.backtrace.join("\n\t")}"
          $stderr.puts "While processing row:\n\t#{row}"
        end
      end

      selected
    end

    def generate_csv(headers, rows)
      CSV.generate do |csv|
        csv << headers
        rows.each { |row| csv << row }
      end
    end
  end


  class Report
    attr_reader :name, :success, :summary, :csv, :csv_including_whitelisted_rows, :unused_whitelist_entries

    private_class_method :initialize

    def initialize(name:, success:, summary:, csv:, csv_including_whitelisted_rows:, unused_whitelist_entries:)
      @name = name
      @success = success
      @summary = summary
      @csv = csv
      @csv_including_whitelisted_rows = csv_including_whitelisted_rows
      @unused_whitelist_entries = unused_whitelist_entries
    end
  end
end
