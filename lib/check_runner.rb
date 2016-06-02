class CheckRunner
  def initialize(env, *check_names)
    Thread.abort_on_exception = true

    checker_db_name = env["CHECKER_DB_NAME"] || CheckerDB.in_memory_db_name
    skip_import = env["SKIP_DATA_IMPORT"] ? true : false
    whitelist_file = env["WHITELIST_FILE"] || 'whitelist.yml'
    @output_dir = env["CHECK_OUTPUT_DIR"] || '.'
    suppress_progress = env["SUPPRESS_PROGRESS"] ? true : false

    checker_db = CheckerDB.new(checker_db_name)
    @check_reporter = Checks::Reporter.new(Whitelist.load(whitelist_file))

    @progress_reporter = suppress_progress ? ProgressReporter.noop : ProgressReporter.new

    @importers = []
    unless skip_import
      @importers << Import::RummagerImporter.new(checker_db, @progress_reporter)
      @importers << Import::PublishingApiImporter.new(checker_db, @progress_reporter)
    end

    @checks = load_checks(checker_db, check_names)
  end

  def run
    run_importers
    check_reports = run_checks
    whitelist_expiry_report = @check_reporter.report_expired_whitelist_entries
    report_results(check_reports + [whitelist_expiry_report])
  end

private

  def load_checks(checker_db, check_names)
    check_files = Dir[File.join(File.dirname(__FILE__), 'checks', '*.rb')]
    check_names_to_run = check_names.empty? ? get_check_names(check_files) : check_names
    check_files.each { |file| require file }
    check_names_to_run.map { |check_name| Checks.const_get(check_name).new(check_name, checker_db, @check_reporter) }
  end

  def get_check_names(check_files)
    check_files.map { |f| File.basename(f, '.rb').split('_').map(&:capitalize).join('') }
  end

  def run_importers
    @progress_reporter.message("setup", "importing data using #{@importers.map(&:class)}")
    @importers.map { |importer| Thread.new { importer.import } }.each(&:join)
  end

  def run_checks
    @progress_reporter.message("setup", "running checks using #{@checks.map(&:class)}")
    @checks.map { |check| Thread.future { check.run_check } }.map(&:value)
  end

  def report_results(reports)
    reports.each { |report| File.write(File.join(@output_dir.to_s, "#{report.name}.csv"), report.csv) }
    reports.each { |report| File.write(File.join(@output_dir.to_s, "#{report.name}_all.csv"), report.csv_including_whitelisted_rows) }
    reports.each { |report| @progress_reporter.message("setup", report.summary) }
    exit_code = reports.all?(&:success) ? 0 : 1
    exit_code
  end
end
