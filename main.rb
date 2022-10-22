
def create_table (name, *columns)
  columns.length > 0 ||  columns = ['id int', 'name varchar(255)']
  het = ''
  for i in 0...columns.length
    het << "#{columns[i]}"
    i == columns.length - 1 ||  het << ', '
  end
  puts het
  $db.execute <<~SQL
    CREATE TABLE IF NOT EXISTS #{name}(
      #{het}
    );
  SQL
end

BEGIN {
  # Setup Gems
  system 'gem install bundler --conservative'
  system('bundle check') || system('bundle install')

  # Setup tcp socket
  require 'socket'
  server = TCPServer.new 2000

  # Setup database
  require 'sqlite3'
  system('mkdir -p db')
  system('touch db/database.db')
  $db = SQLite3::Database.open "db/database.db"
}
  create_table 'ola', 'sol', 'praia'
  puts 'cabou'

END {
  loop do
    Thread.start(server.accept) do |client|
      puts client.gets
      client.puts "Hello !"
      client.close
    end
  end
}

