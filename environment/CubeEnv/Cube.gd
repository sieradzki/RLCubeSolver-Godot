extends Node3D


# Preload the small piece
var piece_scene = preload("res://CubeEnv/Piece.tscn")

@export var cube_size = 3

enum CubeSide { TOP, BOTTOM, LEFT, RIGHT, FRONT, BACK }

func _ready():
	create_cube(cube_size) 
		
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

func get_pieces_on_side(side, layer):
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
