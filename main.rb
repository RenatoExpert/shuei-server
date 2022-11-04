
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
  $controllers = Hash[]
  $clients = []
}

BEGIN { # These methods should be in another ruby script
  def listen_controller(controller)
    loop do
      begin
        controller = $controllers["#{uuid}"]['socket']
        gpio_status = controller.gets
        # Register on controller's gpio_status
        gstatus = JSON.parse!(gpio_status)['gpio_status']
        puts gstatus
        $controllers["#{uuid}"]["gpio_status"] = gstatus
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
        from_client = JSON.parse!(client.gets)
        puts 'new command received'
        uuid = from_client['uuid']
        puts "sending to #{uuid}"
        command = from_client['command']
        args = from_client['args']
        send_command(uuid, Hash[command, args].to_json)
      rescue
        client.close
        break
      end
    end
  end

  def send_status()
    if $clients.length > 0
      for client in $clients
        puts $controllers.to_json
        client.puts $controllers.to_json
      end
    else
      puts 'No client to send message'
    end
  end

  def send_command(json)
    $controllers["#{uuid}"]['socket'].puts json
  end
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

