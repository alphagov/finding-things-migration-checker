module Import
  module Tables
    def self.create_rummager_tables(checker_db)
      checker_db.create_table(
        table_name: "rummager_content",
        columns: [
          'base_path text',
          'content_id text',
          'format text',
          'rummager_index text',
          'is_withdrawn text',
        ],
      )

      checker_db.create_table(
        table_name: "rummager_link",
        columns: [
          "base_path text",
          "link_type text",
          "link_base_path text",
        ],
      )

      checker_db.create_table(
        table_name: "rummager_base_path_content_id",
        columns: [
          "base_path text",
          "content_id text",
        ],
      )
    end

    def self.create_rummager_indexes(checker_db)
      checker_db.create_indexes(
        table_name: "rummager_content",
        index: %w(base_path),
      )

      checker_db.create_indexes(
        table_name: "rummager_link",
        index: %w(base_path link_base_path),
      )

      checker_db.create_indexes(
        table_name: "rummager_base_path_content_id",
        index: %w(base_path content_id),
      )
    end

    def self.create_publishing_api_tables(checker_db)
      checker_db.create_table(
        table_name: 'publishing_api_content',
        columns: [
          'content_id text',
          'publishing_app text',
          'document_type text',
          'schema_name text',
          'ever_published text',
        ],
      )

      checker_db.create_table(
        table_name: 'publishing_api_link',
        columns: [
          'content_id text',
          'link_type text',
          'link_content_id text',
        ],
      )
    end

    def self.create_publishing_api_indexes(checker_db)
      checker_db.create_indexes(
        table_name: "publishing_api_content",
        index: %w(content_id),
      )

      checker_db.create_indexes(
        table_name: "publishing_api_link",
        index: %w(content_id link_content_id),
      )
    end
  end
end
