extends Node3D


# Preload the small piece
var piece_scene = preload("res://CubeEnv/Piece.tscn")

@export var cube_size = 3

enum CubeSide { TOP, BOTTOM, LEFT, RIGHT, FRONT, BACK }

const AXIS_X = Vector3(1, 0, 0)
const AXIS_Y = Vector3(0, 1, 0)
const AXIS_Z = Vector3(0, 0, 1)

var current_rotation_group: Node3D = null

var cube_pieces = Array()
func _ready():
	create_cube(cube_size) 
	
func _input(delta):
	if Input.is_key_pressed(KEY_1):
		rotate_side(CubeSide.BOTTOM, 0, 90)
	elif Input.is_key_pressed(KEY_Q):
		rotate_side(CubeSide.BOTTOM, 0, -90)
	elif Input.is_key_pressed(KEY_2):
		rotate_side(CubeSide.BOTTOM, 1, 90)
	elif Input.is_key_pressed(KEY_W):
		rotate_side(CubeSide.BOTTOM, 1, -90)
	elif Input.is_key_pressed(KEY_3):
		rotate_side(CubeSide.BOTTOM, 2, 90)
	elif Input.is_key_pressed(KEY_E):
		rotate_side(CubeSide.BOTTOM, 2, -90)
	if Input.is_key_pressed(KEY_4):
		rotate_side(CubeSide.LEFT, 0, 90)
	elif Input.is_key_pressed(KEY_R):
		rotate_side(CubeSide.LEFT, 0, -90)
	elif Input.is_key_pressed(KEY_5):
		rotate_side(CubeSide.LEFT, 1, 90)
	elif Input.is_key_pressed(KEY_T):
		rotate_side(CubeSide.LEFT, 1, -90)
	elif Input.is_key_pressed(KEY_6):
		rotate_side(CubeSide.LEFT, 2, 90)
	elif Input.is_key_pressed(KEY_Y):
		rotate_side(CubeSide.LEFT, 2, -90)
	
func rotate_side(side, layer, angle):
	if current_rotation_group:
			disband_rotation_group(current_rotation_group)
	current_rotation_group = create_rotation_group(side, layer)
	rotate_group(current_rotation_group, get_rotation_axis(side), angle)
	
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
	cube_pieces = []
	for x in range(size):
		var layer = []  # Create a new layer
		for y in range(size):
			var row = []  # Create a new row in the current layer
			for z in range(size):
				row.append(null)  # Initialize each cell in the row
			layer.append(row)  # Add the row to the current layer
		cube_pieces.append(layer)  # Add the layer to the cube

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
					cube_pieces[x][y][z] = piece
					# Hide unseen faces
					piece.get_child(CubeSide.TOP).visible = y == size - 1
					piece.get_child(CubeSide.BOTTOM).visible = y == 0
					piece.get_child(CubeSide.LEFT).visible = x == 0
					piece.get_child(CubeSide.RIGHT).visible = x == size - 1
					piece.get_child(CubeSide.BACK).visible = z == 0
					piece.get_child(CubeSide.FRONT).visible = z == size - 1


func get_pieces_on_side(side: CubeSide, layer: int) -> Array:
	var pieces = []
	var size = cube_pieces.size()

	match side:
		CubeSide.TOP:
			for x in range(size):
				for z in range(size):
					if cube_pieces[x][size - 1 - layer][z] != null:
						pieces.append(cube_pieces[x][size - 1 - layer][z])
		CubeSide.BOTTOM:
			for x in range(size):
				for z in range(size):
					if cube_pieces[x][layer][z] != null:
						pieces.append(cube_pieces[x][layer][z])
		CubeSide.LEFT:
			for y in range(size):
				for z in range(size):
					if cube_pieces[layer][y][z] != null:
						pieces.append(cube_pieces[layer][y][z])
		CubeSide.RIGHT:
			for y in range(size):
				for z in range(size):
					if cube_pieces[size - 1 - layer][y][z] != null:
						pieces.append(cube_pieces[size - 1 - layer][y][z])
		CubeSide.FRONT:
			for x in range(size):
				for y in range(size):
					if cube_pieces[x][y][layer] != null:
						pieces.append(cube_pieces[x][y][layer])
		CubeSide.BACK:
			for x in range(size):
				for y in range(size):
					if cube_pieces[x][y][size - 1 - layer] != null:
						pieces.append(cube_pieces[x][y][size - 1 - layer])

	return pieces

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
	
func rotate_group(rotation_group: Node3D, axis: Vector3, angle_degrees: float, duration: float = 0.3):
	var tween = get_tree().create_tween()
	var start_rotation = rotation_group.rotation_degrees
	var end_rotation = start_rotation + axis * angle_degrees

	tween.tween_property(rotation_group, "rotation_degrees", end_rotation, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	tween.play()

	# Updated connection using Signal.connect() and Callable.bind()
	tween.finished.connect(_on_tween_finished.bind(rotation_group))

func _on_tween_finished(rotation_group):
	disband_rotation_group(rotation_group)
	current_rotation_group = null
	
