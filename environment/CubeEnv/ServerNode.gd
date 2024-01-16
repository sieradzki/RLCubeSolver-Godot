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
		if peer.get_available_bytes() > 0:
			var message = peer.get_utf8_string(peer.get_available_bytes())
			print("Received from client: " + message)
			# Process the message and respond
			process_command(message)
			# Only for testing
			#var response = "Message received: " + message
			#peer.put_data(response.to_utf8_buffer())

func process_command(command: String) -> String:
	var parts = command.split(":")
	var json = JSON.new()
	match parts[0]:
		"reset":
			cube_instance.reset_cube()
			return JSON.stringify(cube_instance.get_cube_state())
		"step": # placeholder
			var action = parts[1]
			var result = cube_instance.step(action)
			return JSON.stringify({'next_state': result[0], 'reward': result[1], 'done': result[2], 'info': result[3]})
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
