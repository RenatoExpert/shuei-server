require "test/unit"
require 'socket'

class ServerTest< Test::Unit::TestCase
  def test_communication
    client = TCPSocket.open('localhost', 2000)
    controller = TCPSocket.open('localhost', 2000)
	client.puts '{ "type": "client" }'
	assert_equal "{}\n", client.gets
	controller.puts '{ "type": "controller", "uuid": "tester"}'
	controller.puts '[{"sensor": "true","relay": "true","mode": "serial","theme": "heater"}, {"sensor": "false","relay": "true","mode": "paralel","theme": "light"}]'
	assert_equal %Q({"tester":[{"sensor":"true","relay":"true","mode":"serial","theme":"heater"},{"sensor":"false","relay":"true","mode":"paralel","theme":"light"}]}\n), client.gets
    client.close
	controller.close
  end
end

