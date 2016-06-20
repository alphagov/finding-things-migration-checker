require 'checks/missing_links'
require 'db/checker_db'
require 'import/tables'
require 'reporting/check_reporter'
require 'whitelist/whitelist'

module Checks
  RSpec.describe MissingLinks do
    it "produces success reports given no data in the db" do
      checker_db = make_checker_db
      check_reporter = Reporting::CheckReporter.new(Whitelist.new({}))

      check = MissingLinks.new('MissingLinks', checker_db, check_reporter)

      reports = check.run_check

      expect(reports.size).to be(2)
      expect(reports[0].success).to be(true)
      expect(reports[1].success).to be(true)
    end

    it "reports missing links" do
      checker_db = make_checker_db
      check_reporter = Reporting::CheckReporter.new(Whitelist.new({}))

      rummager_base_paths = %w(a b c)
      insert_rummager_content(checker_db, rummager_base_paths)

      publishing_api_content_ids = [1, 2, 3]
      insert_publishing_api_content(checker_db, publishing_api_content_ids)

      insert_rummager_to_publishing_api_mappings(checker_db, 'a' => 1, 'b' => 2, 'c' => 3)

      insert_rummager_links(checker_db, 'a' => %w(a b), 'c' => ['b'])
      insert_publishing_api_links(checker_db, 1 => [3], 2 => [1, 2], 3 => [2])

      check = MissingLinks.new('MissingLinks', checker_db, check_reporter)

      reports = check.run_check

      expect(reports.size).to be(2)

      expect(reports[0].name).to eq('LinksMissingFromRummager')
      expect(reports[0].success).to be(false)
      expect(reports[0].csv.split("\n")).to contain_exactly(
        'link_type,link_content_id,link_base_path,content_id,base_path,publishing_app,document_type,schema_name',
        'mainstream_browse_pages,3,c,1,a,test_publshing_app,test_document_type,test_schema_name',
        'mainstream_browse_pages,1,a,2,b,test_publshing_app,test_document_type,test_schema_name',
        'mainstream_browse_pages,2,b,2,b,test_publshing_app,test_document_type,test_schema_name',
      )

      expect(reports[1].name).to eq('LinksMissingFromPublishingApi')
      expect(reports[1].success).to be(false)
      expect(reports[1].csv.split("\n")).to contain_exactly(
        'link_type,link_content_id,link_base_path,content_id,base_path,publishing_app,document_type,schema_name',
        'mainstream_browse_pages,1,a,1,a,test_publshing_app,test_document_type,test_schema_name',
        'mainstream_browse_pages,2,b,1,a,test_publshing_app,test_document_type,test_schema_name',
      )
    end

    it "doesn't report missing links for content which can't be mapped rummager <-> publishing api" do
      checker_db = make_checker_db
      check_reporter = Reporting::CheckReporter.new(Whitelist.new({}))

      rummager_base_paths = %w(a b c)
      insert_rummager_content(checker_db, rummager_base_paths)

      publishing_api_content_ids = [1, 2, 3]
      insert_publishing_api_content(checker_db, publishing_api_content_ids)

      # note we don't insert mappings

      insert_rummager_links(checker_db, 'a' => %w(a b), 'c' => ['b'])
      insert_publishing_api_links(checker_db, 1 => [3], 2 => [1, 2], 3 => [2])

      check = MissingLinks.new('MissingLinks', checker_db, check_reporter)

      reports = check.run_check

      expect(reports.size).to be(2)

      expect(reports[0].name).to eq('LinksMissingFromRummager')
      expect(reports[0].success).to be(true)
      expect(reports[1].name).to eq('LinksMissingFromPublishingApi')
      expect(reports[1].success).to be(true)
    end

  private

    def make_checker_db
      checker_db = CheckerDB.new(CheckerDB.in_memory_db_name)

      Import::Tables.create_rummager_tables(checker_db)
      Import::Tables.create_publishing_api_tables(checker_db)
      Import::Tables.create_rummager_indexes(checker_db)
      Import::Tables.create_publishing_api_indexes(checker_db)

      checker_db
    end

    def insert_rummager_content(checker_db, base_paths)
      checker_db.insert_batch(
        table_name: 'rummager_content',
        column_names: %w(base_path content_id format rummager_index is_withdrawn),
        rows: base_paths.map { |base_path| [base_path, nil, 'test_format', 'test_index', 'not_withdrawn'] }
      )
    end

    def insert_publishing_api_content(checker_db, content_ids)
      checker_db.insert_batch(
        table_name: 'publishing_api_content',
        column_names: %w(content_id publishing_app document_type schema_name ever_published),
        rows: content_ids.map { |content_id| [content_id, 'test_publshing_app', 'test_document_type', 'test_schema_name', 'published_at_least_once'] }
      )
    end

    def insert_rummager_to_publishing_api_mappings(checker_db, mappings)
      checker_db.insert_batch(
        table_name: 'rummager_base_path_content_id',
        column_names: %w(base_path content_id),
        rows: mappings.to_a,
      )
    end

    def insert_rummager_links(checker_db, links_hash)
      checker_db.insert_batch(
        table_name: 'rummager_link',
        column_names: %w(base_path link_type link_base_path),
        rows: links_hash.flat_map { |base_path, links| links.map { |link| [base_path, 'mainstream_browse_pages', link] } }
      )
    end

    def insert_publishing_api_links(checker_db, links_hash)
      checker_db.insert_batch(
        table_name: 'publishing_api_link',
        column_names: %w(content_id link_type link_content_id),
        rows: links_hash.flat_map { |content_id, links| links.map { |link| [content_id, 'mainstream_browse_pages', link] } }
      )
    end
  end
end
