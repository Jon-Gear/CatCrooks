class_name EnemyBehaviour
extends Resource

enum Kind { IDLE, SEEK, FLOCK, RANGED_ATTACK, MELEE_ATTACK, DASH_ATTACK, PAIN, DEATH }

@export var kind: Kind = Kind.IDLE
@export var damage: DamageSpec = DamageSpec.new()
@export var attack_range: float = 0.0
@export var attack_cooldown: float = 0.0
@export var telegraph_seconds: float = 0.0
@export var active_from: float = 0.0
@export var active_to: float = 0.0
@export var dash_speed: float = 0.0
@export var dash_seconds: float = 0.0
@export var flinch_seconds: float = 0.3
@export var flock_cohesion: float = 0.1
@export var flock_alignment: float = 0.25
@export var flock_separation: float = 0.45
@export var flock_seek: float = 0.25
