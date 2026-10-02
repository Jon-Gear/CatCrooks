class_name InputAdapter
extends RefCounted

const STICK_DEADZONE := 0.2
const TRIGGER_THRESHOLD := 0.5
const KEY_DIAGONAL := 1.4142135623730951

var actions: PlayerActions
var _pad_was_held: Dictionary = {}
var _triggers_was_held: Dictionary = {}


func _init(p_actions: PlayerActions) -> void:
	assert(p_actions != null, "InputAdapter needs the PlayerActions it reads under")
	actions = p_actions


func read_intent() -> PlayerIntent:
	return PlayerIntent.new(
		_move_direction(),
		_fire_held(),
		_cycle_requested(),
		Input.is_action_just_pressed(actions.pause)
	)


func _move_direction() -> Vector2:
	var keys := Vector2(
		_pressed(actions.move_right) - _pressed(actions.move_left),
		_pressed(actions.move_down) - _pressed(actions.move_up)
	) / KEY_DIAGONAL
	var stick := _stick_direction()
	return stick if stick.length() > keys.length() else keys


func _stick_direction() -> Vector2:
	if not _pad_connected():
		return Vector2.ZERO
	return Vector2(
		_axis(JoyAxis.JOY_AXIS_LEFT_X),
		_axis(JoyAxis.JOY_AXIS_LEFT_Y)
	)


func _fire_held() -> bool:
	return (
		Input.is_action_pressed(actions.fire)
		or _pad_held(JoyButton.JOY_BUTTON_RIGHT_SHOULDER)
		or _trigger_held(JoyAxis.JOY_AXIS_TRIGGER_RIGHT)
	)


func _cycle_requested() -> int:
	if Input.is_action_just_pressed(actions.previous_weapon):
		return -1
	if Input.is_action_just_pressed(actions.next_weapon):
		return 1
	var backwards := _pad_just_pressed(JoyButton.JOY_BUTTON_LEFT_SHOULDER)
	var forwards := _trigger_just_pressed(JoyAxis.JOY_AXIS_TRIGGER_LEFT)
	if backwards == forwards:
		return 0
	return -1 if backwards else 1


func _pressed(action: StringName) -> float:
	return 1.0 if Input.is_action_pressed(action) else 0.0


func _axis(axis: JoyAxis) -> float:
	var reading := Input.get_joy_axis(actions.gamepad_device, axis)
	return 0.0 if absf(reading) < STICK_DEADZONE else reading


func _pad_held(button: JoyButton) -> bool:
	return Input.is_joy_button_pressed(actions.gamepad_device, button)


func _pad_just_pressed(button: JoyButton) -> bool:
	return _just_pressed(_pad_held(button), _pad_was_held, button)


func _trigger_held(axis: JoyAxis) -> bool:
	if not _pad_connected():
		return false
	return _axis(axis) > TRIGGER_THRESHOLD


func _trigger_just_pressed(axis: JoyAxis) -> bool:
	return _just_pressed(_trigger_held(axis), _triggers_was_held, axis)


func _just_pressed(held_now: bool, memory: Dictionary, key: int) -> bool:
	var held_before: bool = memory.get(key, false)
	memory[key] = held_now
	return held_now and not held_before


func _pad_connected() -> bool:
	return actions.gamepad_device in Input.get_connected_joypads()
