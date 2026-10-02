extends "res://addons/gut/test.gd"


func test_a_resting_brother_drives_toward_its_top_speed_by_a_tenth_each_frame() -> void:
	var feel = GameFeel.new()
	var motion = MotionState.new(675.0, feel)
	motion.advance(Vector2.RIGHT)
	assert_almost_eq(motion.velocity().x, 67.5, 0.001)
	motion.advance(Vector2.RIGHT)
	assert_almost_eq(motion.velocity().x, 128.25, 0.001)
	motion.advance(Vector2.RIGHT)
	assert_almost_eq(motion.velocity().x, 182.925, 0.001)


func test_a_driven_brother_takes_about_seven_tenths_of_a_second_to_reach_top_speed() -> void:
	var feel = GameFeel.new()
	var motion = MotionState.new(675.0, feel)
	for frame in 30:
		motion.advance(Vector2.RIGHT)
	assert_lt(motion.velocity().x, 0.99 * 675.0)
	for frame in 14:
		motion.advance(Vector2.RIGHT)
	assert_gte(motion.velocity().x, 0.99 * 675.0)


func test_driving_for_a_while_settles_at_top_speed_and_releasing_settles_at_a_standstill() -> void:
	var feel = GameFeel.new()
	var motion = MotionState.new(675.0, feel)
	for frame in 300:
		motion.advance(Vector2.RIGHT)
	assert_almost_eq(motion.velocity().x, 675.0, 0.5)
	for frame in 300:
		motion.advance(Vector2.ZERO)
	assert_almost_eq(motion.velocity().length(), 0.0, 0.01)


func test_releasing_the_stick_decays_far_faster_than_holding_it() -> void:
	var feel = GameFeel.new()
	var held = MotionState.new(675.0, feel)
	var released = MotionState.new(675.0, feel)
	for frame in 300:
		held.advance(Vector2.RIGHT)
		released.advance(Vector2.RIGHT)
	held.advance(Vector2.RIGHT)
	released.advance(Vector2.ZERO)
	assert_almost_eq(held.velocity().x, 675.0, 0.5)
	assert_almost_eq(released.velocity().x, 405.0, 0.5)


func test_the_extra_resistance_stands_down_while_a_knockback_is_active() -> void:
	var feel = GameFeel.new()
	var with_knockback = MotionState.new(675.0, feel)
	var without_knockback = MotionState.new(675.0, feel)
	for frame in 300:
		with_knockback.advance(Vector2.RIGHT)
		without_knockback.advance(Vector2.RIGHT)
	with_knockback.apply_knockback(Vector2(0.01, 0.0))
	with_knockback.advance(Vector2.ZERO)
	without_knockback.advance(Vector2.ZERO)
	assert_almost_eq(with_knockback.velocity().x, 607.5, 0.5)
	assert_almost_eq(without_knockback.velocity().x, 405.0, 0.5)


func test_a_knockback_decays_by_a_tenth_of_itself_each_frame() -> void:
	var motion = MotionState.new(675.0, GameFeel.new())
	motion.apply_knockback(Vector2(100.0, 0.0))
	motion.advance(Vector2.ZERO)
	assert_almost_eq(motion.velocity().x, 90.0, 0.001)
	motion.advance(Vector2.ZERO)
	assert_almost_eq(motion.velocity().x, 81.0, 0.001)


func test_the_velocity_a_brother_moves_at_is_its_intent_plus_its_knockback() -> void:
	var motion = MotionState.new(675.0, GameFeel.new())
	motion.advance(Vector2.RIGHT)
	motion.apply_knockback(Vector2(50.0, 0.0))
	assert_almost_eq(motion.velocity().x, 117.5, 0.001)


func test_a_shallow_diagonal_snaps_to_a_true_diagonal_and_is_not_flattened() -> void:
	var snapped = MotionState.snap_to_eight_way(Vector2(0.47, -1.0))
	assert_gt(absf(snapped.x), 0.6)
	assert_gt(absf(snapped.y), 0.6)
	assert_almost_eq(rad_to_deg(snapped.angle()), -45.0, 0.001)


func test_a_nearly_cardinal_direction_snaps_to_the_cardinal() -> void:
	assert_eq(MotionState.snap_to_eight_way(Vector2(1.0, 0.05)), Vector2.RIGHT)


func test_every_direction_snaps_to_a_clean_multiple_of_forty_five_degrees() -> void:
	for step in 72:
		var raw := Vector2.from_angle(deg_to_rad(float(step) * 5.0))
		var snapped = MotionState.snap_to_eight_way(raw)
		assert_almost_eq(rad_to_deg(snapped.angle()) / 45.0, round(rad_to_deg(snapped.angle()) / 45.0), 0.001)


func test_no_direction_at_all_snaps_to_no_direction_at_all() -> void:
	assert_eq(MotionState.snap_to_eight_way(Vector2.ZERO), Vector2.ZERO)


func test_a_brother_that_has_never_moved_has_no_facing_at_all() -> void:
	assert_eq(MotionState.new(675.0, GameFeel.new()).facing, Vector2.ZERO)


func test_facing_follows_the_snapped_direction_of_the_current_input() -> void:
	var motion = MotionState.new(675.0, GameFeel.new())
	motion.advance(Vector2.RIGHT)
	assert_eq(motion.facing, Vector2.RIGHT)
	motion.advance(Vector2(0.0, 1.0))
	assert_eq(motion.facing, Vector2.DOWN)
	motion.advance(Vector2(-1.0, 0.0))
	assert_eq(motion.facing, Vector2.LEFT)


func test_facing_holds_its_last_direction_when_input_goes_to_zero() -> void:
	var motion = MotionState.new(675.0, GameFeel.new())
	motion.advance(Vector2(-1.0, -1.0))
	var faced_at_release = motion.facing
	for frame in 60:
		motion.advance(Vector2.ZERO)
	assert_eq(motion.facing, faced_at_release)
	assert_almost_eq(rad_to_deg(motion.facing.angle()), -135.0, 0.001)


func test_a_brother_is_exactly_three_times_as_fast_as_an_enemy() -> void:
	var feel = GameFeel.new()
	var brother = MotionState.new(feel.brother_max_speed, feel)
	var enemy = MotionState.new(EnemyDefinition.new().max_speed, feel)
	assert_eq(brother.max_speed, 675.0)
	assert_eq(enemy.max_speed, 225.0)
	assert_eq(brother.max_speed / enemy.max_speed, 3.0)


func test_the_shipped_game_feel_carries_the_numbers_the_scenes_run_on() -> void:
	var feel = load("res://domain/game_feel.tres")
	assert_true(feel != null, "domain/game_feel.tres is missing")
	assert_eq(feel.friction, 0.1)
	assert_eq(feel.accel, 0.1)
	assert_eq(feel.extra_resistance, 0.3)
	assert_eq(feel.brother_max_speed, 675.0)
	assert_eq(feel.brother_max_speed, 3.0 * EnemyDefinition.new().max_speed)


func test_a_long_mixed_run_never_produces_a_velocity_that_is_not_a_number() -> void:
	var feel = GameFeel.new()
	var motion = MotionState.new(675.0, feel)
	var held := 0
	for frame in 600:
		held = (held + 1) % 7
		if held == 0:
			motion.apply_knockback(Vector2(200.0, -75.0))
		if held < 4:
			motion.advance(Vector2(1.0, -0.3))
		else:
			motion.advance(Vector2.ZERO)
		var velocity = motion.velocity()
		assert_true(not is_nan(velocity.x) and not is_nan(velocity.y), "velocity went NaN on frame %d" % frame)
		assert_true(not is_inf(velocity.x) and not is_inf(velocity.y), "velocity went infinite on frame %d" % frame)
