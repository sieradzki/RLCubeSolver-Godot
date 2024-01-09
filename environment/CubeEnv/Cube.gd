extends Node3D


# Preload the small piece
var piece_scene = preload("res://CubeEnv/Piece.tscn")

@export var cube_size = 5

enum CubeSide { TOP, BOTTOM, LEFT, RIGHT, FRONT, BACK }

func _ready():
	create_cube(cube_size) 

func _input(delta):
	if Input.is_key_pressed(KEY_R):
		rotate_side(CubeSide.RIGHT, true, 1)
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

func get_rotation_axis(side):
	match side:
		CubeSide.FRONT, CubeSide.BACK:
			return Vector3(0, 0, 1)
		CubeSide.LEFT, CubeSide.RIGHT:
			return Vector3(1, 0, 0)
		CubeSide.TOP, CubeSide.BOTTOM:
			return Vector3(0, 1, 0)

func get_rotation_center(side, layer):
	var mid = (cube_size - 1) / 2.0
	var layer_pos = layer - mid
	match side:
		CubeSide.FRONT, CubeSide.BACK:
			return Vector3(mid, mid, layer_pos)
		CubeSide.LEFT, CubeSide.RIGHT:
			return Vector3(layer_pos, mid, mid)
		CubeSide.TOP, CubeSide.BOTTOM:
			return Vector3(mid, layer_pos, mid)
			
func rotate_side(side, clockwise, layer = 0):
	var angle = clockwise if -PI / 2 else PI / 2
	var rotation_axis = get_rotation_axis(side)
	var rotation_center = get_rotation_center(side, layer)

	var pieces = get_side_pieces(side, layer)
	for piece in pieces:
		var local_position = piece.transform.origin - rotation_center
		var rotated_position = local_position.rotated(rotation_axis, angle)
		piece.transform.origin = rotated_position + rotation_center

		# Apply rotation to piece
		piece.rotate_object_local(rotation_axis, angle)


