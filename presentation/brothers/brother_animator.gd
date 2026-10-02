class_name BrotherAnimator
extends Node2D

@onready var _player: AnimationPlayer = $Movement
@onready var _sprite: Sprite2D = $Sprite2D

var performance: BrotherPerformance


func _ready() -> void:
	performance = BrotherPerformance.new()
	_player.animation_finished.connect(_on_animation_finished)
	_player.play(BrotherPerformance.IDLE)


func animate(p_has_input: bool) -> void:
	_play(performance.advance(p_has_input))


func flinch(p_from_front: bool) -> void:
	_play(performance.take_hit(p_from_front))


func face(p_facing: Vector2) -> void:
	if not is_zero_approx(p_facing.x):
		_sprite.scale.x = signf(p_facing.x)


func current_animation() -> StringName:
	return _player.current_animation


func _play(p_animation: StringName) -> void:
	if p_animation != "":
		_player.play(p_animation)


func _on_animation_finished(_animation: StringName) -> void:
	_play(performance.settled())