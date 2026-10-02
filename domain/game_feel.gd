class_name GameFeel
extends Resource

@export_group("Movement")
@export var friction: float = 0.1
@export var accel: float = 0.1
@export var extra_resistance: float = 0.3
@export var brother_max_speed: float = 675.0

@export_group("Camera")
@export var split_threshold: float = 450.0
@export var max_camera_separation: float = 450.0
@export var seam_max_thickness: float = 3.0
@export var camera_zoom: float = 1.2
@export var shake_wave_announce: float = 8.0
@export var shake_wave_announce_seconds: float = 1.0
@export var shake_brother_hit: float = 4.0
@export var shake_brother_hit_seconds: float = 0.5
@export var shake_player_shot: float = 2.5
@export var shake_player_shot_seconds: float = 0.5

@export_group("Hit stop")
@export var hitstop_time_scale: float = 0.25
@export var hitstop_health_divisor: float = 500.0
@export var hitstop_min_seconds: float = 0.06
@export var hitstop_max_seconds: float = 0.2

@export_group("Waves")
@export var wave_intro_seconds: float = 2.0
@export var spawn_offset: float = 75.0
@export var drop_chance: float = 0.5

@export_group("Respawn")
@export var respawn_radius: float = 64.0
@export var revive_seconds: float = 2.5

@export_group("Items")
@export var pickup_radius: float = 40.0
@export var item_bob_radius: float = 32.0
@export var medkit_heal: float = 20.0

@export_group("Audio")
@export var pitch_min: float = 0.8
@export var pitch_max: float = 1.5
@export var melee_pitch_range: float = 0.3
