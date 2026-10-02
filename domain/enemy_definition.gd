class_name EnemyDefinition
extends Resource

enum TargetingRule { CLOSEST, FARTHEST }

@export var id: String = ""
@export var display_name: String = ""
@export var max_health: float = 10.0
@export var max_speed: float = 225.0
@export var nav_threshold: float = 4.0
@export var targeting_rule: TargetingRule = TargetingRule.CLOSEST
@export var behaviours: Array[EnemyBehaviour] = []


func create_health() -> Health:
	return Health.new(max_health)
