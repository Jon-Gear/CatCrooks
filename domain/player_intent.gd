class_name PlayerIntent
extends RefCounted

var move_dir: Vector2 = Vector2.ZERO
var fire_held: bool = false
var cycle_requested: int = 0
var pause_requested: bool = false


func _init(
	p_move_dir: Vector2 = Vector2.ZERO,
	p_fire_held: bool = false,
	p_cycle_requested: int = 0,
	p_pause_requested: bool = false
) -> void:
	move_dir = p_move_dir.normalized() if not p_move_dir.is_zero_approx() else Vector2.ZERO
	fire_held = p_fire_held
	cycle_requested = p_cycle_requested
	pause_requested = p_pause_requested
