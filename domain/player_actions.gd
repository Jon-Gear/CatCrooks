class_name PlayerActions
extends RefCounted

const FIRST_PLAYER := 1
const LAST_PLAYER := 2

var player_number: int = FIRST_PLAYER
var gamepad_device: int = 0
var pause: StringName = &"pause"
var move_left: StringName = &""
var move_right: StringName = &""
var move_up: StringName = &""
var move_down: StringName = &""
var fire: StringName = &""
var previous_weapon: StringName = &""
var next_weapon: StringName = &""


func _init(p_player_number: int = FIRST_PLAYER) -> void:
	assert(
		p_player_number >= FIRST_PLAYER and p_player_number <= LAST_PLAYER,
		"PlayerActions is built for player one or player two only"
	)
	player_number = p_player_number
	gamepad_device = p_player_number - FIRST_PLAYER
	var prefix := "p%d_" % p_player_number
	move_left = StringName(prefix + "move_left")
	move_right = StringName(prefix + "move_right")
	move_up = StringName(prefix + "move_up")
	move_down = StringName(prefix + "move_down")
	fire = StringName(prefix + "fire")
	previous_weapon = StringName(prefix + "prev_weapon")
	next_weapon = StringName(prefix + "next_weapon")


func every_action() -> Array[StringName]:
	return [
		move_left, move_right, move_up, move_down,
		fire, previous_weapon, next_weapon, pause,
	]
