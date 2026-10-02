class_name HitResult
extends RefCounted

var damage: float = 0.0
var knockback: Vector2 = Vector2.ZERO
var died: bool = false
var hitstop_seconds: float = 0.0


func _init(
	p_damage: float = 0.0,
	p_knockback: Vector2 = Vector2.ZERO,
	p_died: bool = false,
	p_hitstop_seconds: float = 0.0
) -> void:
	damage = p_damage
	knockback = p_knockback
	died = p_died
	hitstop_seconds = p_hitstop_seconds
