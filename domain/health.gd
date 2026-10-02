class_name Health
extends RefCounted

var current: float = 0.0
var max_health: float = 0.0


func _init(p_max_health: float = 1.0) -> void:
	assert(p_max_health > 0.0, "Health requires a positive max_health")
	max_health = p_max_health
	current = p_max_health


func is_empty() -> bool:
	return current <= 0.0


func is_full() -> bool:
	return current >= max_health


func apply_damage(amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	var taken: float = minf(amount, current)
	current -= taken
	return taken


func heal(amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	var healed: float = minf(amount, max_health - current)
	current += healed
	return healed


func fill() -> void:
	current = max_health
