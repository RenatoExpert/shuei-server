
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
  $controllers = []
  $clients = []
  $gstates = Hash[] # A state string for each device | Receive from Controllers and send to Client
}

BEGIN { # These methods should be in another ruby script
  def listen_controller(controller, uuid)
    loop do
      begin
        gpio_status = controller.gets
        # Register on gstates
        gstatus = JSON.parse!(gpio_status)['gpio_status']
        puts gstatus
        $gstates["#{uuid}"] = gstatus
        # Update controllers
        puts "received status #{gstatus} from #{uuid}"
        send_status()
      rescue => e
        puts "Error on controller loop #{uuid} error:#{e}"
        controller.close
        break
      end
    end
  end

  def listen_client(client)
    loop do
      begin
        message = client.gets
        send_command (message)
      rescue
        client.close
        break
      end
    end
  end

  def send_status()
    if $clients.length > 0
      for client in $clients
        puts $gstates.to_json
        client.puts $gstates.to_json
      end
    else
      puts 'No client to send message'
    end
  end

  def send_command(message)
    for controller in $controllers
      controller.puts message
    end
  end
}

END {
  loop do
    Thread.start(server.accept) do |newcomer|
      puts "Current gstates #{$gstates}"
      devaddr = newcomer.peeraddr[2]
      begin
        block = JSON.parse!(newcomer.gets)
        type = block['type']
        if type == 'controller'  # In case of controller
          uuid = block['uuid']
          puts "New connection ip:#{devaddr} type:#{type} uuid:#{uuid}"
          $controllers.append(newcomer)
          listen_controller(newcomer, uuid)
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

