# Setup tcp socket
require 'socket'
server = TCPServer.new 2000

# Setup database
require 'dbi'
db_type = "PostgreSQL"
db_name = "JANUSDB"
db_host = "localhost"
db_user = "janus"
db_pswd = "pi"

begin
  # connect to POSTgres server
  dbh = DBI.connect("DBI:#{db_type}:#{db_name}:#{db_host}", db_user, db_pswd)
  server_version = dbh.select_one("SELECT VERSION()")
  puts "Server version: " + row[0]
rescue DBI::DatabaseError => e
  puts "An error occurred"
  puts "Error code: #{e.err}"
  puts "Error message: #{e.errstr}"
ensure
  # disconnect from server
  dbh.disconnect if dbh
end



loop do
  Thread.start(server.accept) do |client|
    puts client.gets
    client.puts "Hello !"
    client.close
  end
end
