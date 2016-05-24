class CheckerDB

  def self.in_memory_db_name
    ':memory:'
  end

  def initialize(checker_db_name)
    @connection = SQLite3::Database.new(checker_db_name)
  end

  def execute(*args)
    begin
      @connection.execute(*args)
    rescue Exception => e
      puts "Query failed: #{args}"
      raise e
    end
  end

  def create_table(table_name:, columns:, index: [])
    query = <<-SQL
      CREATE TABLE #{table_name} (
        #{columns.join(",")}
      )
    SQL

    execute(query)

    # we only handle single-column indexes at the moment
    index.each do |col|
      index_query = <<-SQL
        CREATE INDEX #{table_name}_#{col}_idx ON #{table_name} (#{col});
      SQL
      execute(index_query)
    end
  end

  def insert_batch(table_name:, column_names:, rows:)
    # SQLITE_LIMIT_COMPOUND_SELECT defaults to 500
    rows.each_slice(500) do |slice_rows|
      insert_sqlite_batch(
        table_name: table_name,
        column_names: column_names,
        rows: slice_rows
      )
    end
  end

private

  def insert_sqlite_batch(table_name:, column_names:, rows:)
    return if rows.empty?

    row_placeholder = rows[0].map{ '?' }.join(',')
    cols = column_names.join(',')
    batch_values = "(#{Array.new(rows.size, row_placeholder).join('),(')})"

    query = <<-SQL
    INSERT INTO #{table_name} (#{cols})
    VALUES #{batch_values}
    SQL

    execute(query, rows.flatten)
  end
end
