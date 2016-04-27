require 'pg'

class Database
  def initialize
    @connection = PG.connect('postgresql:///migration_checker')
  end

  def create_table(table_name:, columns:)
    query = <<-SQL
      CREATE TABLE IF NOT EXISTS #{table_name} (
        #{columns.join(",")}
      )
    SQL

    @connection.exec(query)
    @connection.exec("TRUNCATE TABLE #{table_name}")
  end

  def copy_rows(table_name:)
    enco = PG::TextEncoder::CopyRow.new

    @connection.copy_data "COPY #{table_name} FROM STDIN", enco do
      yield
    end
  end

  def copy_row(row)
    @connection.put_copy_data(row)
  end

  def compare!
    query = <<-SQL
      SELECT
        publishing_api.base_path,
        publishing_api.publishing_app,
        rummager.link_base_paths,
        publishing_api.link_base_paths
      FROM publishing_api
      JOIN rummager using(base_path, link_type)
      WHERE publishing_api.link_base_paths <> rummager.link_base_paths
    SQL

    results = @connection.exec(query)
    results.each_row do |row|
      puts row
      puts '------------------------------'
    end

    puts "#{results.ntuples} mismatches found"
  end
end
