extends Node3D


# Preload the small piece
var piece_scene = preload("res://CubeEnv/Piece.tscn")

@export var cube_size = 2
@export var rotation_speed = 0.3
@export var animate = true

enum CubeSide { TOP, BOTTOM, LEFT, RIGHT, FRONT, BACK }

# Rotation axes
const AXIS_X = Vector3(1, 0, 0)
const AXIS_Y = Vector3(0, 1, 0)
const AXIS_Z = Vector3(0, 0, 1)

var current_rotation_group: Node3D = null

# For storing cube's pieces state
var cube_pieces = Array()

var is_rotating = false

func _ready():
	create_cube(cube_size)
	
func _input(delta):
	if is_rotating:
		return
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
	is_rotating = true
	if current_rotation_group:
			disband_rotation_group(current_rotation_group)
	current_rotation_group = create_rotation_group(side, layer)
	rotate_group(current_rotation_group, get_rotation_axis(side), angle)
	update_cube_pieces(side, layer, angle)
	
func get_rotation_axis(side: CubeSide):
	match side:
		CubeSide.RIGHT, CubeSide.LEFT:
			return AXIS_X
		CubeSide.TOP, CubeSide.BOTTOM:
			return AXIS_Y
		CubeSide.FRONT, CubeSide.BACK:
			return AXIS_Z

func create_cube(size):
	# Prepare an array for storing cube's state
	cube_pieces = []
	for x in range(size):
		var layer = []  # Create a new layer
		for y in range(size):
			var row = []  # Create a new row in the current layer
			for z in range(size):
				row.append(null)  # Initialize each cell in the row
			layer.append(row)  # Add the row to the current layer
		cube_pieces.append(layer)  # Add the layer to the cube

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
					cube_pieces[x][y][z] = piece
					# Hide unseen faces
					piece.get_child(CubeSide.TOP).visible = y == size - 1
					piece.get_child(CubeSide.BOTTOM).visible = y == 0
					piece.get_child(CubeSide.LEFT).visible = x == 0
					piece.get_child(CubeSide.RIGHT).visible = x == size - 1
					piece.get_child(CubeSide.FRONT).visible = z == 0
					piece.get_child(CubeSide.BACK).visible = z == size - 1

func get_pieces_on_side(side: CubeSide, layer: int) -> Array:
	var pieces = []
	var size = cube_pieces.size()
	var positions = []
	match side:
		CubeSide.TOP:
			for x in range(size):
				for z in range(size):
					if cube_pieces[x][size - 1 - layer][z] != null:
						pieces.append(cube_pieces[x][size - 1 - layer][z])
						positions.append([x, size-1-layer, z])
		CubeSide.BOTTOM:
			for x in range(size):
				for z in range(size):
					if cube_pieces[x][layer][z] != null:
						pieces.append(cube_pieces[x][layer][z])
						positions.append([x, layer, z])
		CubeSide.LEFT:
			for y in range(size):
				for z in range(size):
					if cube_pieces[layer][y][z] != null:
						pieces.append(cube_pieces[layer][y][z])
						positions.append([layer, y, z])
		CubeSide.RIGHT:
			for y in range(size):
				for z in range(size):
					if cube_pieces[size - 1 - layer][y][z] != null:
						pieces.append(cube_pieces[size - 1 - layer][y][z])
						positions.append([size-1-layer, y, z])
		CubeSide.FRONT:
			for x in range(size):
				for y in range(size):
					if cube_pieces[x][y][layer] != null:
						pieces.append(cube_pieces[x][y][layer])
						positions.append([x, y, layer])
						
		CubeSide.BACK:
			for x in range(size):
				for y in range(size):
					if cube_pieces[x][y][size - 1 - layer] != null:
						pieces.append(cube_pieces[x][y][size - 1 - layer])
						positions.append([x, y, size - 1 - layer])

	return [pieces, positions]

func create_rotation_group(side, layer) -> Node3D:
	var rotation_group = Node3D.new()
	rotation_group.name = "RotationGroup"
	add_child(rotation_group)

	var pieces_on_side = get_pieces_on_side(side, layer)
	var pieces_to_rotate = pieces_on_side[0]
	var pieces_positions = pieces_on_side[1]
	#print(pieces_to_rotate)
	#var positions_after_rotation = rotate_layer_clockwise(pieces_positions, cube_size)
	#var reversed_positions = rotate_layer_counterclockwise(positions_after_rotation, cube_size)
	for piece in pieces_to_rotate:
		piece.get_parent().remove_child(piece)
		rotation_group.add_child(piece)

	return rotation_group
	
func update_cube_pieces(side: CubeSide, layer: int, angle: int):
	var pieces_on_side = get_pieces_on_side(side, layer)
	var pieces_to_rotate = pieces_on_side[0]
	var pieces_positions = pieces_on_side[1]

	var new_positions
	match angle:
		90:
			new_positions = rotate_layer_clockwise(pieces_positions, cube_size, side)
		-90:
			new_positions = rotate_layer_counterclockwise(pieces_positions, cube_size, side)

	# Create a dictionary to map old positions to new pieces
	var position_to_piece = {}
	for i in range(pieces_to_rotate.size()):
		var old_pos = pieces_positions[i]
		var new_piece = pieces_to_rotate[i]
		position_to_piece[old_pos] = new_piece

	# Update the cube_pieces array
	for i in range(new_positions.size()):
		var new_pos = new_positions[i]
		var old_pos = pieces_positions[i]
		var new_piece = position_to_piece[old_pos]
		cube_pieces[new_pos[0]][new_pos[1]][new_pos[2]] = new_piece

func rotate_layer_clockwise(layer: Array, size: int, side: CubeSide) -> Array:
	var rotated_layer = []

	for position in layer:
		var x = position[0]
		var y = position[1]
		var z = position[2]

		var new_x
		var new_y
		var new_z
		match side:
			# Handle horizontal rotation (bottom or top)
			CubeSide.BOTTOM, CubeSide.TOP:
				new_x = z
				new_y = y  # y remains the same for horizontal rotation
				new_z = size - 1 - x

			# Handle vertical rotation (left or right)
			CubeSide.LEFT, CubeSide.RIGHT:
				new_x = x  # x remains the same for vertical rotation
				new_y = size - 1 - z
				new_z = y

		rotated_layer.append(Vector3(new_x, new_y, new_z))

	return rotated_layer

func rotate_layer_counterclockwise(layer: Array, size: int, side: CubeSide) -> Array:
	var rotated_layer = []

	for position in layer:
		var x = position[0]
		var y = position[1]
		var z = position[2]

		var new_x
		var new_y
		var new_z
		match side:
			# Handle horizontal rotation (bottom or top)
			CubeSide.BOTTOM, CubeSide.TOP:
				new_x = size - 1 - z
				new_y = y  # y remains the same for horizontal rotation
				new_z = x

			# Handle vertical rotation (left or right)
			CubeSide.LEFT, CubeSide.RIGHT:
				new_x = x  # x remains the same for vertical rotation
				new_y = z
				new_z = size - 1 - y

		rotated_layer.append(Vector3(new_x, new_y, new_z))

	return rotated_layer

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
	
func rotate_group(rotation_group: Node3D, axis: Vector3, angle_degrees: float, duration: float = rotation_speed):
	var start_rotation = rotation_group.rotation_degrees
	var end_rotation = start_rotation + axis * angle_degrees

	if animate:
		var tween = get_tree().create_tween()
		tween.tween_property(rotation_group, "rotation_degrees", end_rotation, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.play()
		tween.finished.connect(_on_tween_finished.bind(rotation_group))
	else:
		rotation_group.rotation_degrees = end_rotation
		disband_rotation_group(rotation_group)
		current_rotation_group = null
		is_rotating = false

func _on_tween_finished(rotation_group):
	disband_rotation_group(rotation_group)
	current_rotation_group = null
	is_rotating = false
	
