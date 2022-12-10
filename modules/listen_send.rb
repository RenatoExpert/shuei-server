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
			puts 'error with client'
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

