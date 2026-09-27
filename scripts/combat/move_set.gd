class_name MoveSet
extends Resource
## A fighter's moves, editable in the inspector (data/moves/*.tres).

@export var moves: Array[MoveData] = []


func get_move(id: StringName) -> MoveData:
	for move in moves:
		if move.id == id:
			return move
	return null
