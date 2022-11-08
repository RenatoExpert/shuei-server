
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
  def listen_controller(uuid)
    loop do
      begin
        controller = $controllers["#{uuid}"]['socket']
        info_raw = controller.gets
        # Register on controller's gpio_status
		info = JSON.parse!(info_raw)
        puts info
        $controllers["#{uuid}"]["info"] = info
        # Update controllers
        puts "received status #{info} from #{uuid}"
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
        uuid = from_client['uuid']
        command = from_client['command']
        args = from_client['args']
        to_controller = Hash['command' => command, 'args' => args]
        puts "New command to #{uuid} >> #{to_controller}"
        send_command(uuid, to_controller)
      rescue
        client.close
        break
      end
    end
  end

  def send_status()
  	clean_info = Hash[]
	$controllers.each_pair {|uuid, value| clean_info[uuid] = value['info']}
	puts clean_info
    if $clients.length > 0
      for client in $clients
        puts clean_info
        client.puts clean_info
      end
    else
      puts 'No client to send message'
    end
  end

  def send_command(uuid, message)
    begin
      json = message.to_json
      controller = $controllers["#{uuid}"]['socket']
      controller.puts json
    rescue => e
      puts e
    end
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

