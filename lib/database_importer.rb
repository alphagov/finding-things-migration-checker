require 'pg'

# importer = DatabaseImporter.new
# importer.import('publishing_api', data)

class DatabaseImporter
  def connect
    @connection = PG.connect('postgresql:///migration_checker')
    puts @connection
  end

  def create_table(table_name:, columns:)
    query = <<-SQL
      CREATE TABLE IF NOT EXISTS #{table_name} (
        #{columns.join(",")}
      )
    SQL

    @connection.exec(query)
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
end
