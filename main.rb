# Setup tcp socket
require 'socket'
server = TCPServer.new 2000

# Setup database
require 'sqlite3'

begin
  # handling sqlite service
  db = SQLite3::Database.open "db/database.db"
  puts 'connected'
end



loop do
  Thread.start(server.accept) do |client|
    puts client.gets
    client.puts "Hello !"
    client.close
  end
end
