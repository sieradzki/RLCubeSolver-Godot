extends Node

var Piece = preload("res://Piece.tscn")
var pieces = []
@export var size : int = 3

enum FACES { UP, DOWN, RIGHT, LEFT, FRONT, BACK }

func _ready():
	var positions = get_positions(size)
	print(positions)
	var instance: Node3D = Piece.instantiate()
	for x in positions:
		for y in positions:
			for z in positions:
				var piece = instance.duplicate()
				piece.position = Vector3(x, y, z)
				pieces.append(piece)
				add_child(piece)
				piece.get_child(0).get_child(FACES.UP).visible = y == positions[-1]
				piece.get_child(0).get_child(FACES.DOWN).visible = y == positions[0]
				piece.get_child(0).get_child(FACES.RIGHT).visible = x == positions[-1]
				piece.get_child(0).get_child(FACES.LEFT).visible = x == positions[0]
				piece.get_child(0).get_child(FACES.FRONT).visible = z == positions[0]
				piece.get_child(0).get_child(FACES.BACK).visible = z == positions[-1]

func get_positions(size):
	# This makes sure the cube is centered on the scene
	if size % 2 == 0:
		# If the number is even, the positive side will have +1 pieces
		return Array(range((-size / 2)+1, size / 2 + 1))
	else:
		return Array(range(-(size / 2), size / 2 + 1))
