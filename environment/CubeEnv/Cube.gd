extends Node3D


# Preload the small piece
var piece_scene = preload("res://CubeEnv/Piece.tscn")

@export var cube_size = 5

enum CubeSide { TOP, BOTTOM, LEFT, RIGHT, FRONT, BACK }

func _ready():
	create_cube(cube_size) 

func _input(delta):
	if Input.is_key_pressed(KEY_R):
		rotate_side(CubeSide.FRONT, 0, true)
	elif Input.is_key_pressed(KEY_F):
		rotate_side(CubeSide.FRONT, 0, false)
		
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
	for piece in get_children():
		if piece is CSGBox3D:  # Make sure to only consider the cube pieces
			var position = piece.transform.origin  # Use transform.origin for the position
			match side:
				CubeSide.FRONT:
					if position.z == layer:
						pieces.append(piece)
				CubeSide.BACK:
					if position.z == -layer:
						pieces.append(piece)
				# Add similar logic for TOP, BOTTOM, LEFT, RIGHT
	return pieces

func rotate_side(side, layer, clockwise):
	var angle = -PI/2 if clockwise else PI/2
	var rotation_axis = Vector3()
	
	# Assuming the cube is centered at the origin, calculate the rotation center for the front face
	var rotation_center = Vector3(0, 0, -layer)  # for front side, assuming 'layer' is 0 for the frontmost layer

	match side:
		CubeSide.FRONT:
			rotation_axis = Vector3(0, 0, 1)
		# Add cases for other sides

	for piece in get_side_pieces(side, layer):
		# Convert global position to local position by subtracting the global position of the parent node (Cube)
		var local_position = global_transform.affine_inverse() * piece.global_transform.origin
		var new_local_pos = local_position.rotated(rotation_axis, angle)
		
		# Convert the new local position back to global position and apply it
		piece.global_transform.origin = global_transform * new_local_pos

		# Apply rotation to piece
		piece.rotate_object_local(rotation_axis, angle)


