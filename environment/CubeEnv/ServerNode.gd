class_name ServerNode
extends Node

var server := TCPServer.new()
var peer: StreamPeerTCP
var connected = false

var cube_instance

func _ready():
	pass
	#server.listen(4242)
	#cube_instance = get_node("res://CubeEnv/Cube.gd") # Initialize your Cube instance here

func set_cube_instance(cube):
	cube_instance = cube
	
func start_server(port: int):
	print("Server is starting...")
	server.listen(port)
	print("Listening on port {}".format([port], "{}"))
	

func _process(delta):
	if server.is_connection_available():
		peer = server.take_connection()
		connected = true
		print("Client connected")

	if connected:
		peer.poll()  # Update the state of the connection
		if peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			if peer.get_available_bytes() > 0:
				var message = peer.get_utf8_string(peer.get_available_bytes())
				#print("Received from client: " + message):w
				# Process the message and respond
				var response = process_command(message)
				peer.put_data(response.to_utf8_buffer())
		elif peer.get_status() == StreamPeerTCP.STATUS_ERROR or peer.get_status() == StreamPeerTCP.STATUS_NONE:
			print("Client disconnected. Closing application.")
			connected = false
			get_tree().quit()

func process_command(command: String) -> String:
	var parts = command.split(":")
	var json = JSON.new()
	match parts[0]:
		"initialize":
			var init_params = parts[1].split(",")
			if init_params.size() == 2:
				var cube_size = int(init_params[0])
				var animation_enabled = (init_params[1] == "1")
				cube_instance.set_cube_size(cube_size)
				cube_instance.set_animation(false)
				cube_instance.reset_cube(false)
				return JSON.stringify({"status": "initialized"})
			else:
				return JSON.stringify({'error': 'Invalid init parameters'})
		"reset":
			cube_instance.reset_cube(true)
			return JSON.stringify(cube_instance.get_cube_state())
		"step":
			var action = parts[1].split(",")
			if action.size() == 3:
				var side = int(action[0]) # 0 or 2 (horizontal or vertical, maybe I should change naming) 
				var layer = int(action[1]) 
				var angle_ret = int(action[2]) # angle will (probably) be 0 or 1 on agent's side 
				var angle = 90 if angle_ret == 0 else -90
				cube_instance.rotate_side(side, layer, angle)
				var next_state = cube_instance.get_cube_state()
				var reward = int(cube_instance.is_solved())
				var done = int(cube_instance.is_solved())
				var result = [next_state, reward, done]
				return JSON.stringify(result)
			else:
				return JSON.stringify({'error': 'Invalid action format'})
		_:
			return JSON.stringify({'error': 'Unknown command'})

# Send notification that server is closing the connection
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if peer:
			close_client_connection(peer)

func close_client_connection(peer):
	var close_message = "close_connection"
	peer.put_data(close_message.to_utf8_buffer())
	peer.disconnect_from_host()
