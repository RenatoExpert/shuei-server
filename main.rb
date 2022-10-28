
BEGIN {
  # Setup Gems
  system 'gem install bundler --conservative'
  system('bundle check') || system('bundle install')

  # Setup tcp socket
  require 'socket'
  port = 2000
  if ARGV.length > 1
    for i in 0...ARGV.length 
      port = ARGV[i]=="-p" ? ARGV[i+1] : port
    end
  end
  server = TCPServer.new('0.0.0.0', port)
  puts "Serving at #{port}"

  # Setup database
  require_relative "database"
  require 'sqlite3'
  system('mkdir -p db')
  system('touch db/database.db')
  database = Database.new("db/database.db")

  # JSON decoder
  require 'json'

}

END {
  loop do
    Thread.start(server.accept) do |client|
      devaddr = client.peeraddr[2]
      puts "New connection from #{devaddr}"
      timestamp = Time.now
      begin
        block = JSON.parse!(client.gets)
        uuid = block['uuid']
        gstatus = block['gstatus']
        puts "[#{timestamp}] uuid:#{uuid} ip:#{devaddr} status:#{gstatus}"
        #insert_log timestamp, uuid, devaddr, gstatus, cmd
        client.puts '{"cmd":"upgrade"}'
        begin
          exit_code = client.gets
          case exit_code
          when 0
            puts "Pop command"
          # May use something to decode Unix errno, even if code runs in another OS
          #when 1...200 etc
          else
            raise "aaaa"
          end
        rescue
          puts "Bad exit code"
        ensure
          puts "uuid #{uuid} returns #{exit_code}"
        end
      ensure
        client.close
      end
    end
  end
}

