extends "res://addons/gut/test.gd"

const ScriptIndex = preload("res://tests/unit/support/script_index.gd")
const GAME_SESSION := "res://presentation/game_session.gd"
const LOGIC_LAYERS := ["res://domain", "res://application"]
const SOURCE_LAYERS := ["res://domain", "res://application", "res://presentation", "res://infrastructure", "res://editor"]
const INPUT_SEAM := "res://infrastructure/input_adapter.gd"

var _index = ScriptIndex.new()


func test_all_five_layers_exist() -> void:
	for layer in ScriptIndex.LAYER_ROOTS:
		assert_true(DirAccess.dir_exists_absolute(layer), "%s is missing" % layer)


func test_every_domain_type_is_a_resource_or_a_refcounted() -> void:
	for path in _scripts_under(["res://domain"]):
		var base := _index.base_of(path)
		assert_true(base in ["Resource", "RefCounted"], "%s extends %s" % [path, base])


func test_no_domain_or_application_script_extends_a_node() -> void:
	for path in _scripts_under(LOGIC_LAYERS):
		assert_false(_index.is_node_type(_index.base_of(path)), "%s extends a Node (%s)" % [
			path, _index.base_of(path),
		])


func test_no_domain_or_application_script_calls_into_the_scene_tree() -> void:
	for path in _scripts_under(LOGIC_LAYERS):
		var reaches: Array = ScriptIndex.node_reaching_calls(_index.source_of(path))
		assert_eq(reaches, [], "%s reaches the scene tree via %s" % [path, reaches])


func test_no_domain_or_application_script_preloads_a_scene() -> void:
	for path in _scripts_under(LOGIC_LAYERS):
		var scenes: Array = ScriptIndex.scene_preloads(_index.source_of(path))
		assert_eq(scenes, [], "%s preloads scene content: %s" % [path, scenes])


func test_the_input_seam_is_the_only_script_that_touches_input() -> void:
	assert_true(_index.source_of(INPUT_SEAM) != "", "%s is missing" % INPUT_SEAM)
	var allowed := [INPUT_SEAM]
	for path in _scripts_under(SOURCE_LAYERS):
		if not _index.references(_index.source_of(path), "Input"):
			continue
		assert_true(path in allowed, "%s touches Input; only the InputAdapter may" % path)


func test_no_presentation_script_writes_health() -> void:
	for path in _scripts_under(["res://presentation"]):
		var writes: Array = ScriptIndex.health_writes(_index.source_of(path))
		assert_eq(writes, [], "%s writes Health: %s" % [path, writes])


func test_game_session_holds_no_node_in_any_member_it_can_reach() -> void:
	assert_true(_index.source_of(GAME_SESSION) != "", "%s is missing" % GAME_SESSION)
	var chain: Array = _index.node_chain_from(GAME_SESSION)
	assert_eq(chain, [], "GameSession reaches a Node through %s" % str(chain))


func test_game_session_declares_every_member_with_a_type() -> void:
	var untyped: Array = ScriptIndex.untyped_members(_index.source_of(GAME_SESSION))
	assert_eq(untyped, [], "GameSession members need a type to be provably Node-free: %s" % str(untyped))


func test_game_session_accepts_no_node_in_any_signature() -> void:
	for entry in ScriptIndex.signature_types(_index.source_of(GAME_SESSION)):
		var declared: String = entry["type"]
		if declared == "" or not _index.is_known_type(declared):
			fail_test("GameSession %s() leaves its %s type undeclared or unresolvable" % [
				entry["owner"], entry["kind"],
			])
		assert_false(_index.is_node_type(declared), "GameSession %s() takes or returns a Node (%s)" % [
			entry["owner"], declared,
		])


func test_game_session_exposes_state_and_services_and_nothing_else() -> void:
	var members: Dictionary = ScriptIndex.typed_members(_index.source_of(GAME_SESSION))
	assert_eq(members.keys(), ["game_state", "services"])
	assert_eq(members["game_state"], "GameState")
	assert_eq(members["services"], "ServiceRegistry")


func test_the_index_sees_the_scripts_of_every_layer() -> void:
	assert_has(_index.paths(), "res://domain/game_state.gd")
	assert_has(_index.paths(), "res://application/service_registry.gd")
	assert_has(_index.paths(), GAME_SESSION)
	assert_eq(
		_index.class_name_of(GAME_SESSION), "",
		"an autoload script declares no class_name; it would shadow the singleton"
	)


func test_the_detector_catches_a_node_base_class() -> void:
	var index = ScriptIndex.new([])
	assert_true(index.is_node_type("Node"))
	assert_true(index.is_node_type("Node2D"))
	assert_true(index.is_node_type("Control"))
	assert_false(index.is_node_type("Object"))
	assert_false(index.is_node_type("RefCounted"))
	assert_false(index.is_node_type("Resource"))
	assert_false(index.is_node_type("GameState"))
	assert_false(index.is_node_type("float"))
	assert_true(index.is_known_type("float"))
	assert_false(index.is_known_type("Whatever"))


func test_the_detector_catches_scene_tree_reaches() -> void:
	var source := """
func a() -> void:
	var world = get_tree().current_scene
	var node = get_node("Child")
	var pressed = Input.is_action_pressed("fire")
"""
	var reaches: Array = ScriptIndex.node_reaching_calls(source)
	assert_has(reaches, "get_tree")
	assert_has(reaches, "get_node")
	assert_has(reaches, "Input")
	assert_eq(ScriptIndex.node_reaching_calls("var x = 1\nvar sound = AudioServer.bus_count\n").size(), 1)
	assert_eq(ScriptIndex.node_reaching_calls("var x = 1\n"), [])


func test_the_detector_catches_preloaded_scenes_only() -> void:
	assert_eq(ScriptIndex.scene_preloads("const s = preload(\"res://level.tscn\")").size(), 1)
	assert_eq(ScriptIndex.scene_preloads("const s = preload(\"res://domain/axe.tres\")"), [])


func test_the_detector_catches_writes_to_health_and_leaves_reads_alone() -> void:
	var writing := """
func punish(health: Health) -> void:
	health.apply_damage(10.0)
	health.heal(5.0)
	health.fill()
	health.current = 0.0
	health.max_health = 100.0
"""
	assert_eq(ScriptIndex.health_writes(writing).size(), 5)
	var reading := """
func observe(health: Health) -> void:
	var ratio = health.current / health.max_health
	if health.is_empty() or health.is_full():
		draw(_fill_rect(ratio))
"""
	assert_eq(ScriptIndex.health_writes(reading), [])
	assert_eq(ScriptIndex.health_writes("var is_over = health.current == 0.0\n"), [])
	assert_eq(ScriptIndex.health_writes("var is_under = health.current >= 1.0\n"), [])


func test_the_detector_catches_any_reference_to_a_named_singleton() -> void:
	assert_true(ScriptIndex.references("var x = Input.is_action_pressed(\"fire\")", "Input"))
	assert_true(ScriptIndex.references("var x = InputMap.get_action(\"fire\")", "InputMap"))
	assert_false(ScriptIndex.references("var x = 1\n", "Input"))
	assert_false(ScriptIndex.references("var input = read_intent()", "Input"))
	assert_false(ScriptIndex.references("var x = _input.read_intent()", "Input"))


func test_the_detector_catches_nodes_declared_in_signatures() -> void:
	var source := """
func _init(world: Node) -> void:
	pass


func get_camera() -> Camera2D:
	return null
"""
	var declared := Array()
	for entry in ScriptIndex.signature_types(source):
		declared.append(entry["type"])
	assert_eq(declared, ["Node", "void", "Camera2D"])


func test_the_detector_reads_members_params_and_defaults() -> void:
	var source := """
@export var speed: float = 1.0
var health: Health
var untyped


func apply(points: Vector2 = Vector2(2, 3), extra: DamageSpec = null) -> void:
	var local_noise: Node = null
"""
	assert_eq(ScriptIndex.typed_members(source), {"speed": "float", "health": "Health"})
	assert_eq(ScriptIndex.untyped_members(source), ["untyped"])
	var parameters := ScriptIndex.signature_types(source)
	assert_eq(parameters.size(), 3)
	assert_eq(parameters[0]["type"], "Vector2")
	assert_eq(parameters[1]["type"], "DamageSpec")


func _scripts_under(roots: Array) -> Array:
	var found := Array()
	for root in roots:
		for path in _index.paths():
			if path.begins_with(root + "/"):
				found.append(path)
	return found
