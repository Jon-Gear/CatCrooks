class_name AmmoState
extends RefCounted

var current: int = 0
var max_ammo: int = 0
var pack_amount: int = 0


func _init(p_max_ammo: int = 0, p_pack_amount: int = 0) -> void:
	assert(p_max_ammo >= 0, "AmmoState requires a non-negative max_ammo")
	max_ammo = p_max_ammo
	pack_amount = p_pack_amount
	current = p_max_ammo


func is_empty() -> bool:
	return current <= 0


func is_full() -> bool:
	return current >= max_ammo


func consume(amount: int = 1) -> int:
	if amount <= 0:
		return 0
	var taken: int = mini(amount, current)
	current -= taken
	return taken


func add_pack() -> int:
	var added: int = mini(pack_amount, max_ammo - current)
	current += added
	return added


func fill() -> void:
	current = max_ammo
