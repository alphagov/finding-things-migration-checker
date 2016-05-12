class CheckerDB

  def initialize(checker_db_name)
    @connection = SQLite3::Database.new(checker_db_name)
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

  def insert(table_name:, column_names:, row:)
    row = row.class == Hash ? row.values : row
    cols = column_names.join(',')
    values = row.map{ '?' }.join(',')


    query = <<-SQL
    INSERT INTO #{table_name} (#{cols})
    VALUES (#{values})
    SQL

    execute(query, row)
  end

  def self.in_memory_db_name
    ':memory:'
  end

  private
  def execute(*args)
    begin
      @connection.execute(*args)
    rescue Exception => e
      puts "Query failed: #{args}"
      raise e
    end
  end
end
