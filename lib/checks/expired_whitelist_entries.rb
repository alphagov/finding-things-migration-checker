module Checks
  class ExpiredWhitelistEntries
    def initialize(name, checker_db, whitelist)
      @name = name
      @checker_db = checker_db
      @whitelist = whitelist
    end

    def run_check
      headers = %w(check_name expiry_date reason)
      expiries = @whitelist.report_expired_entries(Date.today)
      whitelist_function = @whitelist.get_whitelist_function(@name, headers)
      Report.create(@name, headers, expiries, whitelist_function)
    end
  end
end
