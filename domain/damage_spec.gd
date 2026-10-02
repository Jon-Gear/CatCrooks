class_name DamageSpec
extends Resource

@export var damage: float = 0.0
@export var knockback: float = 0.0


func _init(p_damage: float = 0.0, p_knockback: float = 0.0) -> void:
	damage = p_damage
	knockback = p_knockback
