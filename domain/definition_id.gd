class_name DefinitionId
extends RefCounted

var value: String = ""


static func create(raw: String) -> DefinitionId:
	return DefinitionId.new(raw)


func _init(raw: String = "") -> void:
	value = raw.strip_edges().to_lower()


func to_id() -> String:
	return value


func equals_raw(raw: String) -> bool:
	return value == raw.strip_edges().to_lower()


func matches(other: DefinitionId) -> bool:
	return other != null and other.value == value


func is_empty() -> bool:
	return value == ""


func _to_string() -> String:
	return value
