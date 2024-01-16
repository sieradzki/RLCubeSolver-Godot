extends Node

var cube_instance
var server_instance

func _ready():
	# Instantiate nodes
	cube_instance = $Cube
	server_instance = $ServerNode
	
	# Pass the cube instance to the server
	server_instance.set_cube_instance(cube_instance)

	# Start the server
	server_instance.start_server(4242)

	# Set up cube environment
	reset_environment()
	
func reset_environment():
	cube_instance.reset_cube(false)

func _input(delta):
	""" Testing only """
	if Input.is_key_pressed(KEY_0):
		reset_environment()
	elif Input.is_key_pressed(KEY_P):
		print(cube_instance.is_solved())

