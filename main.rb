
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


BEGIN {
  # Setup Gems
  system 'gem install bundler --conservative'
  system('bundle check') || system('bundle install')

  # Setup tcp socket
  require 'socket'
  port = 2000
  if ARGV.length > 1
    for i in 0...ARGV.length 
      port = ARGV[i]=="-p" ? ARGV[i+1] : port
    end
  end
  server = TCPServer.new port
  puts "Serving at #{port}"

  # Setup database
  require 'sqlite3'
  system('mkdir -p db')
  system('touch db/database.db')
  $db = SQLite3::Database.open "db/database.db"

  # JSON decoder
  require 'json'

}

create_table 'slaves', 'huuid', 'tagname', 'curIP', 'GPIO_Status'
create_table 'logs', 'ID INTEGER PRIMARY KEY AUTOINCREMENT', 'timestamp TEXT', 'devuid TEXT', 'devaddr TEXT', 'priority TEXT', 'message TEXT'


END {
  loop do
    Thread.start(server.accept) do |client|
      timestamp = Time.now
      block = JSON.parse!(client.gets)
      devuid = block['devuid']
      devaddr = client.peeraddr[2]
      priority = block['priority']
      message = block['message']
      puts "[#{timestamp}] uid:#{devuid} ip:#{devaddr} (#{priority}) : #{message}"
      insert_log timestamp, devuid, devaddr, priority, message
      client.puts "Hello !"
      client.close
    end
  end
}

