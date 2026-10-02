class_name WeaponDefinition
extends Resource

enum Emitter { SINGLE, SPREAD }

@export var id: String = ""
@export var display_name: String = ""
@export var is_melee: bool = false
@export var shot_delay: float = 0.25
@export var bullet_speed: float = 600.0
@export var emitter: Emitter = Emitter.SINGLE
@export var pellet_count: int = 1
@export var spread_degrees: float = 1.0
@export var pellet_angles_degrees: PackedFloat32Array = PackedFloat32Array()
@export var damage: DamageSpec = DamageSpec.new()
@export var recoil: float = 0.0
@export var max_ammo: int = 0
@export var ammo_per_pack: int = 0


func create_ammo() -> AmmoState:
	return AmmoState.new(max_ammo, ammo_per_pack)
