extends "res://addons/gut/test.gd"


func test_an_intent_moves_in_the_direction_it_was_given_and_at_no_other_speed() -> void:
	var intent = PlayerIntent.new(Vector2(3.0, 4.0))
	assert_almost_eq(intent.move_dir.x, 0.6, 0.001)
	assert_almost_eq(intent.move_dir.y, 0.8, 0.001)


func test_an_intent_from_an_untouched_stick_moves_nowhere() -> void:
	assert_eq(PlayerIntent.new().move_dir, Vector2.ZERO)


func test_an_intent_carries_the_buttons_along_with_the_direction() -> void:
	var intent = PlayerIntent.new(Vector2.RIGHT, true, 1, true)
	assert_true(intent.fire_held)
	assert_eq(intent.cycle_requested, 1)
	assert_true(intent.pause_requested)


func test_an_intent_asks_for_nothing_by_default() -> void:
	var intent = PlayerIntent.new()
	assert_false(intent.fire_held)
	assert_eq(intent.cycle_requested, 0)
	assert_false(intent.pause_requested)


func test_cycling_backwards_is_the_only_way_to_ask_for_the_previous_weapon() -> void:
	assert_eq(PlayerIntent.new(Vector2.ZERO, false, -1).cycle_requested, -1)
	assert_eq(PlayerIntent.new(Vector2.ZERO, false, 0).cycle_requested, 0)
	assert_eq(PlayerIntent.new(Vector2.ZERO, false, 1).cycle_requested, 1)


func test_how_far_a_direction_is_from_still_never_reaches_the_movement_model() -> void:
	for raw in [Vector2(0.001, 0.0), Vector2(-0.5, 0.5), Vector2(675.0, 675.0), Vector2(0.0, -3.0)]:
		assert_almost_eq(PlayerIntent.new(raw).move_dir.length(), 1.0, 0.001)
