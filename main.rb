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
  require_relative "modules/database"
  system('mkdir -p db')
  system('touch db/database.db')
  database = Database.new("db/database.db")

  # JSON decoder
  require 'json'

  # Stacks
  $controllers = Hash[]
  $clients = []

  # Listen/send methods
  require_relative "modules/listen_send.rb"
}

END {
  loop do
    Thread.start(server.accept) do |newcomer|
      puts "Current controllers #{$controllers}"
      devaddr = newcomer.peeraddr[2]
      begin
        block = JSON.parse!(newcomer.gets)
        type = block['type']
        if type == 'controller'  # In case of controller
          uuid = block['uuid']
          puts "New connection ip:#{devaddr} type:#{type} uuid:#{uuid}"
          $controllers["#{uuid}"]= Hash['socket' => newcomer]
          listen_controller(uuid)
        elsif type == 'client' # In case of client
          puts "New connection ip:#{devaddr} type:#{type}"
          $clients.append(newcomer)
          send_status()
          listen_client(newcomer)
        end
      rescue
        newcomer.close
      end
    end
  end
}

