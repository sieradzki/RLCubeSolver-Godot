extends Node

var piece = preload("res://Piece.tscn")
var pieces = []
@export var size : int = 3

func _ready():
	var positions = get_positions(size)
	var instance: Node3D = piece.instantiate()
	for x in positions:
		for y in positions:
			for z in positions:
				var cube = instance.duplicate()
				cube.position = Vector3(x, y, z)
				pieces.append(cube)
				add_child(cube)

func get_positions(size):
	if size % 2 == 0:
		# If the number is even, the positive side will have +1 pieces
		return Array(range((-size / 2)+1, size / 2 + 1))
	else:
		return Array(range(-(size / 2), size / 2 + 1))
