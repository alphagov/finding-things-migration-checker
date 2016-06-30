require 'checks/rummager_link_targets_missing_from_rummager'
require 'db/checker_db'
require 'import/tables'
require 'reporting/check_reporter'
require 'whitelist/whitelist'

require 'helpers/checker_db_helper'

module Checks
  RSpec.describe RummagerLinkTargetsMissingFromRummager do
    include TestHelpers::CheckerDbHelper

    it "produces success reports given no data in the db" do
      checker_db = make_checker_db
      check_reporter = Reporting::CheckReporter.new(Whitelist.new({}))

      check = RummagerLinkTargetsMissingFromRummager.new('RummagerLinkTargetsMissingFromRummager', checker_db, check_reporter)

      reports = check.run_check

      expect(reports.size).to be(1)
      expect(reports[0].success).to be(true)
    end

    it "reports missing link targets" do
      checker_db = make_checker_db
      check_reporter = Reporting::CheckReporter.new(Whitelist.new({}))

      rummager_base_paths = %w(a b c)
      insert_rummager_content(checker_db, rummager_base_paths)

      insert_rummager_links(checker_db, 'a' => %w(a b x y), 'c' => %w(z b c))

      check = RummagerLinkTargetsMissingFromRummager.new('RummagerLinkTargetsMissingFromRummager', checker_db, check_reporter)

      reports = check.run_check

      expect(reports.size).to be(1)

      expect(reports[0].success).to be(false)
      expect(reports[0].csv.split("\n")).to contain_exactly(
        "link,link_type,item,item_format,item_index",
        "x,mainstream_browse_pages,a,test_format,test_index",
        "y,mainstream_browse_pages,a,test_format,test_index",
        "z,mainstream_browse_pages,c,test_format,test_index",
      )
    end
  end
end
