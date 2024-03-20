class_name Cube
extends Node3D


# Preload the small piece
var piece_scene = preload("res://CubeEnv/Piece.tscn")

@export var cube_size = 2
@export var rotation_speed = 0.3
@export var animate = true

enum CubeSide { TOP, BOTTOM, LEFT, RIGHT, FRONT, BACK }
enum FaceColor { WHITE, YELLOW, GREEN, BLUE, ORANGE, RED}

# Rotation axes
const AXIS_X = Vector3(1, 0, 0)
const AXIS_Y = Vector3(0, 1, 0)
const AXIS_Z = Vector3(0, 0, 1)

var active_rotation_pieces: Node3D = null

# For storing cube's pieces state
var cube_pieces = Array()
var cube_faces # face objects
var cube_state = [] # colors on each side

var prev_positions # previous face positions
var current_positions # current face positions

var is_rotating = false

var rng = RandomNumberGenerator.new()

func _ready():
	reset_cube(false, 3)
	print(cube_state)
	pass
	
func _input(delta):
	""" For testing rotations """
	if is_rotating:
		return
	if Input.is_key_pressed(KEY_1):
		rotate_side(CubeSide.TOP, 0, -90)
	elif Input.is_key_pressed(KEY_Q):
		rotate_side(CubeSide.TOP, 0, -90)
	elif Input.is_key_pressed(KEY_2):
		rotate_side(CubeSide.TOP, 1, 90)
	elif Input.is_key_pressed(KEY_W):
		rotate_side(CubeSide.TOP, 1, -90)
	elif Input.is_key_pressed(KEY_3):
		rotate_side(CubeSide.TOP, 2, 90)
	elif Input.is_key_pressed(KEY_E):
		rotate_side(CubeSide.TOP, 2, -90)
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
	elif Input.is_key_pressed(KEY_9):
		scramble_cube(10)

func set_cube_size(size):
	""" Set cube size """
	cube_size = size

func set_animation(enabled):
	""" Enable or disable animation """
	animate = enabled

func create_cube():
	""" Create cube """
	# Prepare an array for storing cube's state
	cube_pieces = []
	for x in range(cube_size):
		var layer = []  # Create a new layer
		for y in range(cube_size):
			var row = []  # Create a new row in the current layer
			for z in range(cube_size):
				row.append(null)  # Initialize each cell in the row
			layer.append(row)  # Add the row to the current layer
		cube_pieces.append(layer)  # Add the layer to the cube

	# Center the cube on the scene
	var offset = (cube_size - 1) / 2.0
	# Dynamically create cube of given size
	for x in range(cube_size):
		for y in range(cube_size):
			for z in range(cube_size):
				if x == 0 or x == cube_size - 1 or y == 0 or y == cube_size - 1 or z == 0 or z == cube_size - 1:
					# Instantiate the small cube piece
					var piece = piece_scene.instantiate()
					# Set the correct position
					var position = Vector3(x, y, z) - Vector3(offset, offset, offset)
					piece.transform.origin = position
					# Add piece as a child of big cube
					add_child(piece)
					cube_pieces[x][y][z] = piece
					# Hide unseen faces
					piece.get_child(CubeSide.TOP).visible = y == cube_size - 1
					piece.get_child(CubeSide.BOTTOM).visible = y == 0
					piece.get_child(CubeSide.LEFT).visible = x == 0
					piece.get_child(CubeSide.RIGHT).visible = x == cube_size - 1
					piece.get_child(CubeSide.FRONT).visible = z == 0
					piece.get_child(CubeSide.BACK).visible = z == cube_size - 1
					
	var ret = get_initial_faces_and_positions()
	cube_faces = ret[0]
	current_positions = ret[1]

func reset_cube(scramble, random_moves=1):
	""" Reset cube to the solved state """
	#print("Reseting environment...")
	# Perform cleanup
	for child in get_children():
		# Check if the child is an instance of CSGBox3D
		if child is CSGBox3D:
			child.queue_free()  # Remove only CSGBox3D nodes
			
	cube_pieces = Array()
	cube_faces # face objects
	cube_state = [] # colors on each side
	
	create_cube()
	if scramble:
		#print("Scrambling the cube...")
		scramble_cube(random_moves)
	#print("Environment ready")

	var prev_positions # previous face positions
	var current_positions # current face positions

	is_rotating = false

				
func scramble_cube(random_moves=3):
	""" Scramble the cube """
	rng.randomize() 

	var num_rotations = random_moves
	var last_side = -1 
	var last_layer = -1
	var last_angle = 0
	
	var i = 0
	while i < num_rotations:
		var side = rng.randi_range(0, 1)
		var layer = rng.randi_range(0, cube_size - 1)
		var angle = rng.randi_range(0, 1) * 2 - 1
		
		# Ensure the new move is not an immediate reversal of the last move
		if side == last_side and layer == last_layer and angle == -last_angle:
			continue
		
		if side:
			rotate_side(CubeSide.BOTTOM, layer, angle * 90)
		else:
			rotate_side(CubeSide.LEFT, layer, angle * 90)

		last_side = side
		last_layer = layer
		last_angle = angle
		i+=1

func get_cube_state() -> Array:
	""" Get cube state """
	return cube_state

func is_solved():
	""" Check if the cube is solved """
	for side in cube_state:
		var first_face = side[0][0]
		for row in side:
			for face in row:
				if face != first_face:
					return false
	return true
	
func is_solved_state(state_string):
	""" Check if the state is a solved state """
	var json = JSON.new()
	var error = json.parse(state_string)
	var state = json.data
	for side in state:
		var first_face = side[0][0]
		
		for row in side:
			for face in row:
				if face != first_face:
					return false
	return true
	
func get_initial_faces_and_positions():
	""" Get initial state of cube's faces with their positions """
	var all_faces = []
	var all_positions = []

	for side_index in range(6):  # 6 faces of the cube
		var faces_on_side = []
		var positions_on_side = []
		var colors_on_side = []  # This will be a 2D array

		var side_pieces_info = get_pieces_on_side(side_index, 0)
		var pieces_on_side = side_pieces_info[0]

		# Initialize a dictionary to group faces by row
		var rows = {}

		for piece_index in range(pieces_on_side.size()):
			var piece = pieces_on_side[piece_index]
			for child_index in range(piece.get_children().size()):
				var face = piece.get_child(child_index)

				# Check if face is on the current side and visible
				if child_index == side_index and face.visible:
					var pos = round_vector(face.get_global_position())
					var row_key = pos.y if side_index in [CubeSide.LEFT, CubeSide.RIGHT, CubeSide.FRONT, CubeSide.BACK] else pos.x

					if not rows.has(row_key):
						rows[row_key] = {'faces': [], 'positions': [], 'colors': []}
					
					rows[row_key]['faces'].append(face)
					rows[row_key]['positions'].append(pos)
					rows[row_key]['colors'].append(child_index)

		# Sort and append rows to the respective lists
		var sorted_keys = rows.keys()
		sorted_keys.sort()
		for key in sorted_keys:
			faces_on_side.append(rows[key]['faces'])
			positions_on_side.append(rows[key]['positions'])
			colors_on_side.append(rows[key]['colors'])

		all_faces.append(faces_on_side)
		all_positions.append(positions_on_side)
		cube_state.append(colors_on_side)

	return [all_faces, all_positions, cube_state]
	
func get_faces_positions(faces):
	""" Get positions of faces """
	var positions = []
	for side in faces:
		var side_positions = []
		for row in side:
			var row_positions = []
			for face in row:
				row_positions.append(round_vector(face.get_global_position()))
			side_positions.append(row_positions)
		positions.append(side_positions)
	return positions

func round_vector(vector):
	""" Helper function to round vector components """
	return Vector3(snapped(vector.x, 0.001), snapped(vector.y, 0.001), snapped(vector.z, 0.001))

				
func print_faces(faces):
	""" Print faces positions """
	for side in faces:
		var row = []
		for face in side:
			row.append(face.get_global_position())
		print(row)
	

func rotate_side(side, layer, angle):
	""" Rotate given side and layer by angle """
	is_rotating = true
	if active_rotation_pieces:
			disband_rotation_pieces(active_rotation_pieces)
	active_rotation_pieces = group_pieces_to_rotate(side, layer)
	rotate_pieces(active_rotation_pieces, get_rotation_axis(side), angle)
	update_cube_pieces(side, layer, angle)
	
func get_rotation_axis(side: CubeSide):
	""" Get rotation axis based on CubeSide """
	match side:
		CubeSide.RIGHT, CubeSide.LEFT:
			return AXIS_X
		CubeSide.TOP, CubeSide.BOTTOM:
			return AXIS_Y
		CubeSide.FRONT, CubeSide.BACK:
			return AXIS_Z

func init_face(color, size):
	""" Initialize face """
	var face = []
	for y in range(size):
		var row = []
		for x in range(size):
			row.append(color)
		face.append(row)
	return face

func get_pieces_on_side(side: CubeSide, layer: int) -> Array:
	""" Get pieces on a given side and layer """
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

func group_pieces_to_rotate(side, layer) -> Node3D:
	""" Group pieces to rotate """
	var rotation_pieces = Node3D.new()
	rotation_pieces.name = "RotationPieces"
	add_child(rotation_pieces)

	var pieces_on_side = get_pieces_on_side(side, layer)
	var pieces_to_rotate = pieces_on_side[0]
	#print(pieces_to_rotate)
	#var positions_after_rotation = rotate_layer_clockwise(pieces_positions, cube_size)
	#var reversed_positions = rotate_layer_counterclockwise(positions_after_rotation, cube_size)
	for piece in pieces_to_rotate:
		piece.get_parent().remove_child(piece)
		rotation_pieces.add_child(piece)

	return rotation_pieces
	
func update_cube_pieces(side: CubeSide, layer: int, angle: int):
	""" Update pieces positions """
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
	""" Rotate given side and layer clockwise """
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
	""" Rotate given side and layer counter-clockwise """
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

func disband_rotation_pieces(rotation_pieces: Node3D):
	""" Disband group of pieces to rotate """
	# Get the global transform of pieces before disbanding the group
	var group_global_transform = rotation_pieces.global_transform

	while rotation_pieces.get_child_count() > 0:
		var piece = rotation_pieces.get_child(0)
		rotation_pieces.remove_child(piece)

		# Calculate the new local transform for the piece
		var new_local_transform = group_global_transform * piece.transform
		piece.global_transform = new_local_transform

		# Reparent the piece to the main cube node
		add_child(piece)

	# Remove the rotation group from the scene tree
	rotation_pieces.queue_free()

func update_cube_state(): 
	""" Update cube_state array with new pieces positions """
	var temp_cube_state = cube_state.duplicate(true)
	var temp_cube_faces = cube_faces.duplicate(true)
	for side in range(6):
		for row in range(cube_size):
			for col in range(cube_size):
				var pos = prev_positions[side][row][col]
				# Check if there was a change in position
				if pos != current_positions[side][row][col]:
					var res = find_face_pos(pos)
					var new_side = res[0]
					var new_row = res[1]
					var new_col = res[2]
					cube_state[side][row][col] = temp_cube_state[new_side][new_row][new_col]
				
func find_face_pos(pos):
	""" Find position of a face """
	for side in range(6):
		for row in range(cube_size):
			for col in range(cube_size):
				if current_positions[side][row][col] == pos:
					return [side, row, col]
	
func rotate_pieces(rotation_pieces: Node3D, axis: Vector3, angle_degrees: float, duration: float = rotation_speed):
	""" Rotate group of pieces """
	var start_rotation = rotation_pieces.rotation_degrees
	var end_rotation = start_rotation + axis * angle_degrees

	if animate:
		var tween = get_tree().create_tween()
		tween.tween_property(rotation_pieces, "rotation_degrees", end_rotation, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.play()
		tween.finished.connect(_on_tween_finished.bind(rotation_pieces))
	else:
		rotation_pieces.rotation_degrees = end_rotation
		disband_rotation_pieces(rotation_pieces)
		active_rotation_pieces = null
		prev_positions = current_positions
		current_positions = get_faces_positions(cube_faces)
		update_cube_state()
		is_rotating = false
		#print(cube_state)

func _on_tween_finished(rotation_pieces):
	disband_rotation_pieces(rotation_pieces)
	active_rotation_pieces = null
	prev_positions = current_positions
	current_positions = get_faces_positions(cube_faces)
	update_cube_state()
	is_rotating = false
	
