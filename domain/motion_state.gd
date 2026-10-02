class_name MotionState
extends RefCounted

const SNAP_STEP := PI / 4.0

var feel: GameFeel
var max_speed: float = 0.0
var intended_velocity: Vector2 = Vector2.ZERO
var knockback: Vector2 = Vector2.ZERO
var facing: Vector2 = Vector2.ZERO


func _init(p_max_speed: float, p_feel: GameFeel) -> void:
	assert(p_max_speed > 0.0, "MotionState requires a positive max_speed")
	assert(p_feel != null, "MotionState requires the GameFeel that owns the feel constants")
	max_speed = p_max_speed
	feel = p_feel


static func snap_to_eight_way(direction: Vector2) -> Vector2:
	if direction.is_zero_approx():
		return Vector2.ZERO
	var snapped := Vector2.from_angle(snappedf(direction.angle(), SNAP_STEP))
	return Vector2(_cardinal(snapped.x), _cardinal(snapped.y))


static func _cardinal(component: float) -> float:
	return 0.0 if is_zero_approx(component) else component


func advance(move_dir: Vector2) -> void:
	_drive_intended(move_dir)
	knockback = knockback.lerp(Vector2.ZERO, feel.friction)


func velocity() -> Vector2:
	return intended_velocity + knockback


func apply_knockback(impulse: Vector2) -> void:
	knockback += impulse


func knockback_active() -> bool:
	return not knockback.is_zero_approx()


func _drive_intended(move_dir: Vector2) -> void:
	if move_dir.is_zero_approx():
		intended_velocity = intended_velocity.lerp(Vector2.ZERO, _deceleration())
		return
	intended_velocity = intended_velocity.lerp(move_dir.normalized() * max_speed, feel.accel)
	facing = snap_to_eight_way(move_dir)


func _deceleration() -> float:
	return feel.friction if knockback_active() else feel.friction + feel.extra_resistance
