
BEGIN {
  # Setup Gems
  system 'gem install bundler --conservative'
  system('bundle check') || system('bundle install')

  # Setup tcp socket
  require 'socket'
  host = '0.0.0.0'
  port = 2000
  if ARGV.length > 1
    for i in 0...ARGV.length 
      port = ARGV[i]=="-p" ? ARGV[i+1] : port
    end
  end
  server = TCPServer.new(host, port)
  puts "Serving at #{port}"

  # Setup database
  require_relative "database"
  system('mkdir -p db')
  system('touch db/database.db')
  database = Database.new("db/database.db")

  # JSON decoder
  require 'json'

  # Stacks
  controllers = []
  clients = []
  gstates = {} # A state string for each device | Receive from Controllers and send to Client
}

END {
  loop do
    Thread.start(server.accept) do |client|
      devaddr = client.peeraddr[2]
      block = JSON.parse!(client.gets)
      timestamp = Time.now
      puts "[#{timestamp}]New connection ip:#{devaddr} block:#{block}"
      if block['type'] == 'controller'  # In case of controller
        uuid = block['uuid']
        gstatus = block['gstatus']
        gstates[uuid] = gstatus
        puts "[#{timestamp}] uuid:#{uuid} ip:#{devaddr} status:#{gstatus}"
        #insert_log timestamp, uuid, devaddr, gstatus, cmd
      elsif block ['type'] == 'client' # In case of client
        client.puts JSON.generate(gstates)
      end
    end
  end
}

