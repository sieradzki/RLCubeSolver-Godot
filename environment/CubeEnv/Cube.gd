extends Node3D


# Preload the small piece
var piece_scene = preload("res://CubeEnv/Piece.tscn")

@export var cube_size = 5

enum CubeSide { TOP, BOTTOM, LEFT, RIGHT, FRONT, BACK }
var layer = -2
const AXIS_X = Vector3(1, 0, 0)
const AXIS_Y = Vector3(0, 1, 0)
const AXIS_Z = Vector3(0, 0, 1)
var current_rotation_group: Node3D = null

func _ready():
	create_cube(cube_size) 
	
func _input(delta):
	if Input.is_key_pressed(KEY_1):
		rotate_side(CubeSide.RIGHT, 0, 90)
	elif Input.is_key_pressed(KEY_Q):
		rotate_side(CubeSide.RIGHT, 0, -90)
	elif Input.is_key_pressed(KEY_2):
		rotate_side(CubeSide.RIGHT, 1, 90)
	elif Input.is_key_pressed(KEY_W):
		rotate_side(CubeSide.RIGHT, 1, -90)
	elif Input.is_key_pressed(KEY_3):
		rotate_side(CubeSide.RIGHT, 2, 90)
	elif Input.is_key_pressed(KEY_E):
		rotate_side(CubeSide.RIGHT, 2, -90)
	if Input.is_key_pressed(KEY_4):
		rotate_side(CubeSide.FRONT, 0, 90)
	elif Input.is_key_pressed(KEY_R):
		rotate_side(CubeSide.FRONT, 0, -90)
	elif Input.is_key_pressed(KEY_5):
		rotate_side(CubeSide.FRONT, 1, 90)
	elif Input.is_key_pressed(KEY_T):
		rotate_side(CubeSide.FRONT, 1, -90)
	elif Input.is_key_pressed(KEY_6):
		rotate_side(CubeSide.FRONT, 2, 90)
	elif Input.is_key_pressed(KEY_Y):
		rotate_side(CubeSide.FRONT, 2, -90)
	
func rotate_side(side, layer, angle):
	if current_rotation_group:
			disband_rotation_group(current_rotation_group)
	current_rotation_group = create_rotation_group(side, layer)
	rotate_group(current_rotation_group, get_rotation_axis(side), angle)
	current_rotation_group = null
	
func get_rotation_axis(side: CubeSide):
	match side:
		CubeSide.RIGHT, CubeSide.LEFT:
			return AXIS_X
		CubeSide.TOP, CubeSide.BOTTOM:
			return AXIS_Y
		CubeSide.FRONT, CubeSide.BACK:
			return AXIS_Z

func create_cube(size):
	# Center the cube on the scene
	var offset = (size - 1) / 2.0
	# Dynamically create cube of given size
	for x in range(size):
		for y in range(size):
			for z in range(size):
				if x == 0 or x == size - 1 or y == 0 or y == size - 1 or z == 0 or z == size - 1:
					# Instantiate the small cube piece
					var piece = piece_scene.instantiate()
					# Set the correct position
					var position = Vector3(x, y, z) - Vector3(offset, offset, offset)
					piece.transform.origin = position
					# Add piece as a child of big cube
					add_child(piece)
					# Hide unseen faces
					piece.get_child(CubeSide.TOP).visible = y == size - 1
					piece.get_child(CubeSide.BOTTOM).visible = y == 0
					piece.get_child(CubeSide.LEFT).visible = x == 0
					piece.get_child(CubeSide.RIGHT).visible = x == size - 1
					piece.get_child(CubeSide.BACK).visible = z == 0
					piece.get_child(CubeSide.FRONT).visible = z == size - 1


func is_in_layer(pos, axis, layer) -> bool:
	var half_size = cube_size / 2
	return int(abs(pos[axis]) + 0.5) == half_size - layer

func get_pieces_on_side(side: CubeSide, layer: int) -> Array:
	var pieces = []
	for piece in get_children():
		var pos = piece.transform.origin
		var half_size = cube_size / 2

		match side:
			CubeSide.TOP:
				if pos.y > half_size - 1 and is_in_layer(pos, 1, layer):
					pieces.append(piece)

			CubeSide.BOTTOM:
				if pos.y < -half_size + 1 and is_in_layer(pos, 1, layer):
					pieces.append(piece)

			CubeSide.LEFT:
				if pos.x < -half_size + 1 and is_in_layer(pos, 0, layer):
					pieces.append(piece)

			CubeSide.RIGHT:
				if pos.x > half_size - 1 and is_in_layer(pos, 0, layer):
					pieces.append(piece)

			CubeSide.FRONT:
				if pos.z < -half_size + 1 and is_in_layer(pos, 2, layer):
					pieces.append(piece)

			CubeSide.BACK:
				if pos.z > half_size - 1 and is_in_layer(pos, 2, layer):
					pieces.append(piece)

	return pieces

func is_approx(value1: float, value2: float, tolerance: float = 0.01) -> bool:
	return abs(value1 - value2) <= tolerance

func create_rotation_group(side, layer) -> Node3D:
	var rotation_group = Node3D.new()
	rotation_group.name = "RotationGroup"
	add_child(rotation_group)

	var pieces_to_rotate = get_pieces_on_side(side, layer)
	for piece in pieces_to_rotate:
		piece.get_parent().remove_child(piece)
		rotation_group.add_child(piece)

	return rotation_group

func disband_rotation_group(rotation_group: Node3D):
	# Get the global transform of the rotation group
	var group_global_transform = rotation_group.global_transform

	while rotation_group.get_child_count() > 0:
		var piece = rotation_group.get_child(0)
		rotation_group.remove_child(piece)

		# Calculate the new local transform for the piece
		var new_local_transform = group_global_transform * piece.transform
		piece.global_transform = new_local_transform

		# Reparent the piece to the main cube node
		add_child(piece)

	# Remove the rotation group from the scene tree
	rotation_group.queue_free()
	
func rotate_group(rotation_group: Node3D, axis: Vector3, angle_degrees: float, duration: float = 0.1):
	var tween = get_tree().create_tween()
	var start_rotation = rotation_group.rotation_degrees
	var end_rotation = start_rotation + axis * angle_degrees

	tween.tween_property(rotation_group, "rotation_degrees", end_rotation, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	tween.play()

	# Updated connection using Signal.connect() and Callable.bind()
	tween.finished.connect(_on_tween_finished.bind(rotation_group))

func _on_tween_finished(rotation_group):
	disband_rotation_group(rotation_group)
	
