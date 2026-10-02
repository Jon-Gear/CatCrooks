class_name ServiceRegistry
extends RefCounted

var game_state: GameState


func _init(state: GameState) -> void:
	assert(state != null, "ServiceRegistry requires the round GameState")
	game_state = state
