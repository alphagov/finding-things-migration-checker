class CheckRunner
  def initialize(*check_names)
    Thread.abort_on_exception = true

    publishing_api_url = ENV["PUBLISHING_API_URL"] || 'http://publishing-api.dev.gov.uk/v2/grouped_content_and_links'
    checker_db_name = ENV["CHECKER_DB_NAME"] || CheckerDB.in_memory_db_name
    skip_import = ENV["SKIP_DATA_IMPORT"] ? true : false
    whitelist_file = ENV["WHITELIST_FILE"] || 'whitelist.yml'

    checker_db = CheckerDB.new(checker_db_name)
    whitelist = Whitelist.load(whitelist_file)

    progress_reporter = ProgressReporter.new

    @importers = []
    unless skip_import
      @importers << Import::RummagerImporter.new(checker_db, progress_reporter)
      @importers << Import::PublishingApiImporter.new(checker_db, progress_reporter, publishing_api_url)
    end

    @checks = CheckRunner.load_checks(checker_db, whitelist, *check_names)
  end

  def run
    run_importers
    reports = run_checks
    report_results(reports)
  end

  def self.load_checks(checker_db, whitelist, *check_names)
    check_files = File.join(File.dirname(__FILE__), 'checks', '*.rb')
    Dir[check_files].each { |file| require file }
    check_names.map { |check_name| Checks.const_get(check_name).new(check_name, checker_db, whitelist) }
  end

  private_class_method :load_checks

private

  def run_importers
    puts "importing data using #{@importers.map(&:class)}"
    @importers.map { |importer| Thread.new { importer.import } }.each(&:join)
  end

  def run_checks
    puts "running checks using #{@checks.map(&:class)}"
    @checks.map { |check| Thread.future { check.run_check } }.map(&:value)
  end

  def report_results(reports)
    reports.each { |report| File.write("#{report.name}.csv", report.csv) }
    reports.each { |report| puts report.summary }
    exit_code = reports.all?(&:success) ? 0 : 1
    exit_code
  end
end
