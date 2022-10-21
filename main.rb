# Setup tcp socket
require 'socket'
server = TCPServer.new 2000

# Setup database
require 'pg'
db_type = "PostgreSQL"
db_name = "janusdb"
db_host = "localhost"
db_user = "janus"
db_pswd = "pi"

begin
  # connect to POSTgres server
  conn = PG.connect(dbname: db_name, user: db_user)
  puts 'connected'
ensure
  # disconnect from server
  conn.disconnect if conn
end



loop do
  Thread.start(server.accept) do |client|
    puts client.gets
    client.puts "Hello !"
    client.close
  end
end
