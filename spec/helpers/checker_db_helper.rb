module TestHelpers
  module CheckerDbHelper
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
