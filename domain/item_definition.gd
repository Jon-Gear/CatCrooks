class_name ItemDefinition
extends Resource

enum Kind { RANGE, MELEE, MEDKIT }

@export var id: String = ""
@export var display_name: String = ""
@export var kind: Kind = Kind.RANGE
@export var despawn_seconds: float = 5.0
