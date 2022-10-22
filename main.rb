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

  # handling sqlite service
  db = SQLite3::Database.open "db/database.db"
  puts 'connected'
}


loop do
  Thread.start(server.accept) do |client|
    puts client.gets
    client.puts "Hello !"
    client.close
  end
end
