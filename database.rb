require 'sqlite3'
class Database
  def initialize (dbpath)
    $db = SQLite3::Database.open(dbpath)
    create_table 'slaves', 'huuid', 'tagname', 'curIP', 'GPIO_Status'
    create_table 'logs', 'ID INTEGER PRIMARY KEY AUTOINCREMENT', 'timestamp TEXT', 'devuid TEXT', 'devaddr TEXT', 'priority TEXT', 'message TEXT'
  end

  def create_table (name, *values)
    values.length > 0 ||  values = ['id int', 'name varchar(255)']
    $db.execute <<~SQL
      CREATE TABLE IF NOT EXISTS #{name}(
        #{values.join(", ")}
      );
    SQL
  end

  def insert_row (table, columns, *values)
    col_list = columns ? "('#{columns.join("', '")}')" : ' '
    values = values.join("', '")
    p values
    $db.execute "INSERT INTO #{table}  #{col_list} VALUES ('#{values}')"
  end

  def insert_log (timestamp, devuid, devaddr, priority, message)
    insert_row 'logs', ['timestamp', 'devuid', 'devaddr', 'priority', 'message'], timestamp, devuid, devaddr, priority, message
  end

end

