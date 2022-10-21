require 'socket'

server = TCPServer.new 2000

loop do
  Thread.start(server.accept) do |client|
    puts client.gets
    client.puts "Hello !"
    client.close
  end
end
