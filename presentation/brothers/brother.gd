class_name Brother
extends CharacterBody2D

@export var player_number: int = PlayerActions.FIRST_PLAYER
@export var max_health: float = 100.0
@export var feel: GameFeel

@onready var _animator: BrotherAnimator = $Visuals

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
	$HealthBar.bind(health)


func _physics_process(_delta: float) -> void:
	if _input == null:
		return
	var intent := _input.read_intent()
	motion.advance(intent.move_dir)
	velocity = motion.velocity()
	move_and_slide()
	_animator.animate(not intent.move_dir.is_zero_approx())
	_animator.face(motion.facing)


func take_hit(p_from_front: bool) -> void:
	_animator.flinch(p_from_front)