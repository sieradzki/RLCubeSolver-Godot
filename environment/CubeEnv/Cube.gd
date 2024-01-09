extends Node3D


# Preload the small piece
var piece_scene = preload("res://CubeEnv/Piece.tscn")

@export var cube_size = 5

enum CubeSide { TOP, BOTTOM, LEFT, RIGHT, FRONT, BACK }

func _ready():
	create_cube(cube_size) 

func _input(delta):
	if Input.is_key_pressed(KEY_R):
		rotate_side(CubeSide.LEFT, 1, true)
	elif Input.is_key_pressed(KEY_F):
		rotate_side(CubeSide.FRONT, 0, false)
	elif Input.is_key_pressed(KEY_U):
		rotate_side(CubeSide.TOP, 0, true)
	elif Input.is_key_pressed(KEY_D):
		rotate_side(CubeSide.BOTTOM, cube_size - 1, false)
	elif Input.is_key_pressed(KEY_L):
		rotate_side(CubeSide.RIGHT, cube_size - 1, true)
	elif Input.is_key_pressed(KEY_B):
		rotate_side(CubeSide.BACK, 1, false)
	# Handling for rotating different layers
	elif Input.is_key_pressed(KEY_1):
		rotate_side(CubeSide.LEFT, 0, true)
	elif Input.is_key_pressed(KEY_2):
		rotate_side(CubeSide.LEFT, 1, true)
	elif Input.is_key_pressed(KEY_3):
		rotate_side(CubeSide.LEFT, 2, true)
		
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


func get_side_pieces(side, layer):
	var pieces = []
	var middle = cube_size / 2
	var half_size = (cube_size - 1) / 2.0
	for piece in get_children():
		if piece is CSGBox3D:
			var position = piece.transform.origin
			match side:
				CubeSide.FRONT:
					if cube_size % 2 == 0 and (position.z == half_size or position.z == -half_size):
						if layer == 0 and position.z == -half_size:
							pieces.append(piece)
						elif layer == 1 and position.z == half_size:
							pieces.append(piece)
					elif cube_size % 2 == 1 and position.z == -layer:
						pieces.append(piece)
				CubeSide.BACK:
					if cube_size % 2 == 0 and (position.z == half_size or position.z == -half_size):
						if layer == 0 and position.z == half_size:
							pieces.append(piece)
						elif layer == 1 and position.z == -half_size:
							pieces.append(piece)
					elif cube_size % 2 == 1 and position.z == layer:
						pieces.append(piece)
				CubeSide.LEFT:
					if cube_size % 2 == 0 and (position.x == half_size or position.x == -half_size):
						if layer == 0 and position.x == -half_size:
							pieces.append(piece)
						elif layer == 1 and position.x == half_size:
							pieces.append(piece)
					elif cube_size % 2 == 1 and position.x == -layer:
						pieces.append(piece)
				CubeSide.RIGHT:
					if cube_size % 2 == 0 and (position.x == half_size or position.x == -half_size):
						if layer == 0 and position.x == half_size:
							pieces.append(piece)
						elif layer == 1 and position.x == -half_size:
							pieces.append(piece)
					elif cube_size % 2 == 1 and position.x == layer:
						pieces.append(piece)
				CubeSide.TOP:
					if cube_size % 2 == 0 and (position.y == half_size or position.y == -half_size):
						if layer == 0 and position.y == half_size:
							pieces.append(piece)
						elif layer == 1 and position.y == -half_size:
							pieces.append(piece)
					elif cube_size % 2 == 1 and position.y == layer:
						pieces.append(piece)
				CubeSide.BOTTOM:
					if cube_size % 2 == 0 and (position.y == half_size or position.y == -half_size):
						if layer == 0 and position.y == -half_size:
							pieces.append(piece)
						elif layer == 1 and position.y == half_size:
							pieces.append(piece)
					elif cube_size % 2 == 1 and position.y == -layer:
						pieces.append(piece)
	return pieces
			
func rotate_side(side, layer, clockwise):
	var angle = -PI / 2 if clockwise else PI / 2
	var rotation_axis = Vector3()
	var rotation_center = Vector3()

	# Determine the axis and center of rotation based on the side
	match side:
		CubeSide.FRONT:
			rotation_axis = Vector3(0, 0, 1)
			rotation_center = Vector3(0, 0, -layer)
		CubeSide.BACK:
			rotation_axis = Vector3(0, 0, -1)
			rotation_center = Vector3(0, 0, layer)
		CubeSide.LEFT:
			rotation_axis = Vector3(1, 0, 0)
			rotation_center = Vector3(-layer, 0, 0)
		CubeSide.RIGHT:
			rotation_axis = Vector3(-1, 0, 0)
			rotation_center = Vector3(layer, 0, 0)
		CubeSide.TOP:
			rotation_axis = Vector3(0, 1, 0)
			rotation_center = Vector3(0, layer, 0)
		CubeSide.BOTTOM:
			rotation_axis = Vector3(0, -1, 0)
			rotation_center = Vector3(0, -layer, 0)

	# Get the pieces for the specified side
	var pieces = get_side_pieces(side, layer)
	
	for piece in pieces:
		# Convert global position to local position
		var local_position = global_transform.affine_inverse() * piece.global_transform.origin
		# Calculate the rotated position
		var new_local_pos = (local_position - rotation_center).rotated(rotation_axis, angle) + rotation_center
		# Convert the new local position back to global position and apply it
		piece.global_transform.origin = global_transform * new_local_pos
		# Apply rotation to piece
		piece.rotate_object_local(rotation_axis, angle)


