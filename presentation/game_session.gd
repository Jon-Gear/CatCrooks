extends Node

var game_state: GameState
var services: ServiceRegistry


func _init() -> void:
	game_state = GameState.new()
	services = ServiceRegistry.new(game_state)
