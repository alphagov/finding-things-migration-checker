class CheckRunner

  def initialize(*check_names)

    # todo: dev mode - file based db, option to run importer/checker separately.

    Thread.abort_on_exception = true

    publishing_api_url = ENV["PUBLISHING_API_URL"] || 'http://publishing-api.dev.gov.uk/v2/grouped_content_and_links'
    checker_db_name = ENV["CHECKER_DB_NAME"] || CheckerDB.in_memory_db_name
    skip_import = ENV["SKIP_DATA_IMPORT"] ? true : false

    checker_db = CheckerDB.new(checker_db_name)
    progress_reporter = ProgressReporter.new

    @importers = []
    unless skip_import
      @importers << Import::RummagerImporter.new(checker_db, progress_reporter)
      @importers << Import::PublishingApiImporter.new(checker_db, progress_reporter, publishing_api_url)
    end

    @checks = CheckRunner.load_checks(checker_db, *check_names)
  end

  def run
    run_importers
    run_checks
    report_results
  end

private

  def run_importers
    puts "importing data using #{@importers.map(&:class)}"
    @importers.map { |importer| Thread.new { importer.import } }.each(&:join)
  end

  def run_checks
    puts "running checks using #{@checks.map(&:class)}"
    @checks.map { |check| Thread.new { check.run_check } }.each(&:join)
  end

  def report_results
    # aggregate return codes, print out any reports for non-0 codes
    # @checks.each { |check| puts check.report }
    # exit with aggregated code
  end

  def self.load_checks(checker_db, *check_names)
    check_files = File.join(File.dirname(__FILE__), 'checks', '*.rb')
    Dir[check_files].each { |file| require file }
    check_names.map { |check_name| Checks.const_get(check_name).new(checker_db) }
  end
end
