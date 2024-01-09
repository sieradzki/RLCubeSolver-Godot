extends Node3D

@export var speed = 0.5
@export var zoom_speed = 0.1
var initial_distance = 6
var distance_from_cube = initial_distance
var camera_node

func _ready():
	camera_node = get_node("OrbitCamera")
	update_camera_position()

func _input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_motion = event.relative
		var current_rotation_degrees = rotation_degrees
		current_rotation_degrees.y += mouse_motion.x * speed
		current_rotation_degrees.x += mouse_motion.y * speed

		# Clamp the rotation on the X-axis to prevent flipping
		current_rotation_degrees.x = clamp(current_rotation_degrees.x, -90, 90)
		rotation_degrees = current_rotation_degrees

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		distance_from_cube -= zoom_speed
		update_camera_position()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		distance_from_cube += zoom_speed
		update_camera_position()

	distance_from_cube = distance_from_cube

func update_camera_size(size):
	distance_from_cube = initial_distance + size - 3
	distance_from_cube = distance_from_cube
	update_camera_position()

func update_camera_position():
	var new_transform = camera_node.transform
	new_transform.origin = Vector3(0, 0, distance_from_cube)
	camera_node.transform = new_transform
	print(camera_node.transform)
