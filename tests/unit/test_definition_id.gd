extends "res://addons/gut/test.gd"


func test_an_id_holds_the_value_it_was_built_from() -> void:
	assert_eq(DefinitionId.create("revolver").to_id(), "revolver")


func test_an_id_is_case_insensitive_like_every_definition_id() -> void:
	assert_eq(DefinitionId.create("Assault Rifle").to_id(), "assault rifle")


func test_an_id_trims_surrounding_whitespace() -> void:
	assert_eq(DefinitionId.create("  Shotgun  ").to_id(), "shotgun")


func test_an_id_equals_a_raw_value_whatever_its_case() -> void:
	var id = DefinitionId.create("Revolver")
	assert_true(id.equals_raw("revolver"))
	assert_true(id.equals_raw("REVOLVER"))
	assert_false(id.equals_raw("axe"))


func test_two_ids_built_from_the_same_value_match() -> void:
	assert_true(DefinitionId.create("axe").matches(DefinitionId.create("AXE")))
	assert_false(DefinitionId.create("axe").matches(DefinitionId.create("medkit")))


func test_an_id_stringifies_to_its_value() -> void:
	assert_eq(str(DefinitionId.create("medkit")), "medkit")


func test_an_id_reports_whether_it_is_empty() -> void:
	assert_true(DefinitionId.create("").is_empty())
	assert_false(DefinitionId.create("axe").is_empty())


func test_a_drop_table_picks_a_weighted_id() -> void:
	var table = DropTable.new()
	table.weights = {"medkit": 5, "revolver": 5, "axe": 4, "shotgun": 3, "minigun": 1}
	var picked: Array = []
	var random := RandomNumberGenerator.new()
	random.seed = 12345
	for roll in 600:
		picked.append(table.pick(random).to_id())
	assert_gt(picked.size(), 1)
	assert_has(picked, "medkit")
	assert_has(picked, "minigun")


func test_a_drop_table_with_nothing_in_it_picks_nothing() -> void:
	var table = DropTable.new()
	assert_true(table.pick().is_empty())
