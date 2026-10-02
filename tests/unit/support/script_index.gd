extends RefCounted

const VARIANT_BUILTINS := [
	"Nil", "void", "bool", "int", "float", "String", "Vector2i", "Vector2", "Rect2i", "Rect2",
	"Vector3i", "Vector3", "Transform2D", "Vector4i", "Vector4", "Plane", "Quaternion",
	"AABB", "Basis", "Transform3D", "Projection", "Color", "StringName", "NodePath",
	"RID", "Object", "Callable", "Signal", "Dictionary", "Array", "PackedByteArray",
	"PackedInt32Array", "PackedInt64Array", "PackedFloat32Array", "PackedFloat64Array",
	"PackedStringArray", "PackedVector2Array", "PackedVector3Array", "PackedColorArray",
	"PackedVector4Array",
]

const NODE_REACHING_CALLS := [
	"get_tree", "get_node", "get_parent", "find_child", "get_node_or_null",
]

const NODE_REACHING_SINGLETONS := [
	"Input", "AudioServer", "DisplayServer", "InputMap",
]

const LAYER_ROOTS := [
	"res://domain", "res://application", "res://infrastructure", "res://presentation",
	"res://editor",
]

var _sources: Dictionary = {}
var _class_paths: Dictionary = {}


func _init(roots: Array = LAYER_ROOTS) -> void:
	for root in roots:
		for path in _gd_files(root):
			var source := _read(path)
			_sources[path] = source
			var declared := declared_class_name(source)
			if declared != "" and not _class_paths.has(declared):
				_class_paths[declared] = path


func paths() -> Array:
	return _sources.keys()


func source_of(path: String) -> String:
	return _sources.get(path, "")


func class_name_of(path: String) -> String:
	return declared_class_name(_sources.get(path, ""))


func display_name_of(path: String) -> String:
	var declared := class_name_of(path)
	return declared if declared != "" else path.get_file().get_basename()


func base_of(path: String) -> String:
	return _resolve_reference(extends_target(_sources.get(path, "")))


func is_node_type(type_name: String) -> bool:
	if type_name == "" or type_name in VARIANT_BUILTINS:
		return false
	if ClassDB.class_exists(type_name):
		return ClassDB.is_parent_class(type_name, "Node")
	return _is_node_class(type_name, {})


func is_known_type(type_name: String) -> bool:
	if type_name == "" or type_name in VARIANT_BUILTINS:
		return true
	return ClassDB.class_exists(type_name) or _class_paths.has(type_name)


func node_chain_from(path: String) -> Array:
	return _node_chain_from(path, [], {})


static func extends_target(source: String) -> String:
	var expression := RegEx.new()
	expression.compile("(?m)^extends\\s+(?:\"([^\"]+)\"|([A-Za-z_][\\w]*))")
	var found := expression.search(source)
	if found == null:
		return ""
	if found.get_string(1) != "":
		return found.get_string(1)
	return found.get_string(2)


static func declared_class_name(source: String) -> String:
	var expression := RegEx.new()
	expression.compile("(?m)^class_name\\s+([A-Za-z_][\\w]*)")
	var found := expression.search(source)
	return "" if found == null else found.get_string(1)


static func typed_members(source: String) -> Dictionary:
	var found := Dictionary()
	for declaration in _top_level_declarations(source, "var"):
		if declaration["type"] != "":
			found[declaration["name"]] = declaration["type"]
	return found


static func untyped_members(source: String) -> Array:
	var found := Array()
	for declaration in _top_level_declarations(source, "var"):
		if declaration["type"] == "":
			found.append(declaration["name"])
	return found


static func node_reaching_calls(source: String) -> Array:
	var calls := _matches(source, "\\b(%s)\\s*\\(" % "|".join(NODE_REACHING_CALLS))
	var singletons := _matches(source, "\\b(%s)\\s*\\." % "|".join(NODE_REACHING_SINGLETONS))
	calls.append_array(singletons)
	return calls


static func scene_preloads(source: String) -> Array:
	return _matches(source, "\"[^\"]+\\.(tscn|scn)\"|'[^']+\\.(tscn|scn)'")


static func signature_types(source: String) -> Array:
	var found := Array()
	for header in _func_headers(source):
		for parameter in _split_parameters(header["parameters"]):
			var declared := RegEx.new()
			declared.compile("([A-Za-z_][\\w]*)\\s*:\\s*([A-Za-z_][\\w]*)")
			var matched := declared.search(parameter)
			if matched != null:
				found.append({
					"kind": "param",
					"owner": header["name"],
					"name": matched.get_string(1),
					"type": matched.get_string(2),
				})
		found.append({"kind": "return", "owner": header["name"], "name": "", "type": header["returns"]})
	return found


static func _top_level_declarations(source: String, keyword: String) -> Array:
	var expression := RegEx.new()
	expression.compile(
		"(?m)^(?:@\\w+(?:\\([^)]*\\))?\\s+)*%s\\s+([A-Za-z_][\\w]*)\\s*(?::\\s*([A-Za-z_][\\w]*))?\\s*(?:=|\\n|$)"
		% keyword
	)
	var found := Array()
	for result in expression.search_all(source):
		found.append({"name": result.get_string(1), "type": result.get_string(2)})
	return found


static func _func_headers(source: String) -> Array:
	var found := Array()
	var pending := ""
	for line in source.split("\n"):
		pending += line.split("#")[0]
		if not pending.strip_edges().begins_with("func "):
			pending = ""
			continue
		if _parens_balanced(pending):
			found.append(_parse_func_header(pending.strip_edges()))
			pending = ""
	return found


static func _parse_func_header(text: String) -> Dictionary:
	var open := text.find("(")
	var close := text.rfind(")")
	if open == -1 or close == -1:
		return {"name": "", "parameters": "", "returns": ""}
	var name := text.substr(4, open - 4).strip_edges()
	if name.begins_with("static "):
		name = name.substr(7).strip_edges()
	var returns := ""
	var tail := text.substr(close + 1).strip_edges()
	if tail.begins_with("->"):
		var declared := RegEx.new()
		declared.compile("^->\\s*([A-Za-z_][\\w]*)")
		var matched := declared.search(tail)
		if matched != null:
			returns = matched.get_string(1)
	return {"name": name, "parameters": text.substr(open + 1, close - open - 1), "returns": returns}


static func _split_parameters(parameters: String) -> Array:
	var found := Array()
	var depth := 0
	var quote := ""
	var current := ""
	for character in parameters:
		if quote != "":
			current += character
			if character == quote:
				quote = ""
			continue
		if character == "\"" or character == "'":
			quote = character
		elif character in ["(", "[", "{"]:
			depth += 1
		elif character in [")", "]", "}"]:
			depth -= 1
		if character == "," and depth == 0:
			found.append(current.strip_edges())
			current = ""
			continue
		current += character
	if current.strip_edges() != "":
		found.append(current.strip_edges())
	return found


static func _parens_balanced(text: String) -> bool:
	var depth := 0
	var quote := ""
	for character in text:
		if quote != "":
			if character == quote:
				quote = ""
			continue
		if character == "\"" or character == "'":
			quote = character
		elif character == "(":
			depth += 1
		elif character == ")":
			depth -= 1
			if depth < 0:
				return true
	return depth == 0


static func _matches(source: String, pattern: String) -> Array:
	var expression := RegEx.new()
	expression.compile(pattern)
	var found := Array()
	for result in expression.search_all(source):
		found.append(result.get_string(1) if result.get_string(1) != "" else result.get_string())
	return found


func _is_node_class(declared: String, seen: Dictionary) -> bool:
	if seen.has(declared):
		return false
	seen[declared] = true
	var path: String = _class_paths.get(declared, "")
	if path == "":
		return false
	return is_node_type(base_of(path))


func _node_chain_from(path: String, chain: Array, seen: Dictionary) -> Array:
	if seen.has(path):
		return []
	seen[path] = true
	var held := chain + [display_name_of(path)]
	var members := typed_members(_sources.get(path, ""))
	for member in members.keys():
		var member_type: String = members[member]
		var member_chain := held + [member]
		if is_node_type(member_type):
			return member_chain
		var member_path: String = _class_paths.get(member_type, "")
		if member_path != "":
			var deeper := _node_chain_from(member_path, member_chain, seen)
			if not deeper.is_empty():
				return deeper
	return []


func _resolve_reference(reference: String) -> String:
	if not reference.begins_with("res://"):
		return reference
	var declared := declared_class_name(_read(reference))
	return declared if declared != "" else reference


func _gd_files(root: String) -> Array:
	var found := Array()
	var directory := DirAccess.open(root)
	if directory == null:
		return found
	for entry in directory.get_files():
		if entry.ends_with(".gd"):
			found.append(root.path_join(entry))
	for entry in directory.get_directories():
		found.append_array(_gd_files(root.path_join(entry)))
	return found


func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()
