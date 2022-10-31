
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
  command_stack = [] # To-do list | Receive from Client and send to Controllers
  gstates = {} # A state string for each device | Receive from Controllers and send to Client
}

END {
  loop do
    Thread.start(server.accept) do |client|
      devaddr = client.peeraddr[2]
      block = JSON.parse!(client.gets)
      timestamp = Time.now
      puts "New connection ip:#{devaddr} block:#{block}"
      if block['type'] == 'controller'  # In case of controller
        begin
          uuid = block['uuid']
          gstatus = block['gstatus']
          gstates[uuid] = gstatus
          puts "[#{timestamp}] uuid:#{uuid} ip:#{devaddr} status:#{gstatus}"
          #insert_log timestamp, uuid, devaddr, gstatus, cmd
          command = {
            "cmd" => "rest"
          }
          for item in command_stack
            if item["uuid"] == uuid
              command = item
              command_stack.delete(command)
              break
            end
          end
          client.puts JSON.generate(command)
          if command['cmd']!='rest'
            begin
              exit_code = client.gets
              puts exit_code
              if exit_code == 0
                puts "Pop command"
              else
                raise "uuid:#{uuid} Not successful"
              # May use something to decode Unix errno, even if code runs in another OS
              # when 1...200 etc
              end
            rescue
              puts "Bad exit code"
            ensure
              puts "uuid #{uuid} returns #{exit_code}"
            end
          end
        end
      elsif block ['type'] == 'client' # In case of client
        commands = block['commands']
        for command in commands
          command_stack.append(command)
        end
        client.puts JSON.generate(gstates)
      end
      client.close
    end
  end
}

