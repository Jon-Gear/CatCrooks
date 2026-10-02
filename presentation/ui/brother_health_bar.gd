class_name BrotherHealthBar
extends Node2D

const FILL_SIZE := Vector2(35.0, 7.0)

@export var height_offset: float = -75.0

@onready var _fill: Sprite2D = $Fill
@onready var _label: Label = $Label

var _health: Health
var _shown: String = ""


func _ready() -> void:
	position.y = height_offset


func bind(p_health: Health) -> void:
	assert(p_health != null, "A health bar needs the Health it reads")
	_health = p_health
	_refresh(true)


func _process(_delta: float) -> void:
	_refresh(false)


func _refresh(force: bool) -> void:
	if _health == null:
		return
	var ratio := 0.0 if _health.max_health <= 0.0 else _health.current / _health.max_health
	var label := "%d / %d" % [roundi(_health.current), roundi(_health.max_health)]
	if force or label != _shown:
		_shown = label
		_fill.region_rect = Rect2(Vector2.ZERO, Vector2(FILL_SIZE.x * ratio, FILL_SIZE.y))
		_label.text = label
