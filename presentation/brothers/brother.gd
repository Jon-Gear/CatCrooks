class_name Brother
extends CharacterBody2D

@export var player_number: int = PlayerActions.FIRST_PLAYER
@export var max_health: float = 100.0
@export var feel: GameFeel
@export var facing_base_rotation: float = 0.0

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _health_bar: BrotherHealthBar = $HealthBar

var health: Health
var motion: MotionState
var actions: PlayerActions

var _input: InputAdapter


func _ready() -> void:
	if feel == null:
		push_error("A Brother needs a GameFeel assigned in the inspector")
		return
	health = Health.new(max_health)
	motion = MotionState.new(feel.brother_max_speed, feel)
	actions = PlayerActions.new(player_number)
	_input = InputAdapter.new(actions)
	_health_bar.bind(health)


func _physics_process(_delta: float) -> void:
	if _input == null:
		return
	var intent := _input.read_intent()
	motion.advance(intent.move_dir)
	velocity = motion.velocity()
	move_and_slide()
	_face_the_way_it_last_moved()


func _face_the_way_it_last_moved() -> void:
	if motion.facing.is_zero_approx():
		return
	_sprite.rotation = facing_base_rotation + motion.facing.angle()
