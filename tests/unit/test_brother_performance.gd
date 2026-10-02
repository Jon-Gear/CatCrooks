extends "res://addons/gut/test.gd"


func test_a_new_brother_is_idling() -> void:
	var performance = BrotherPerformance.new()
	assert_eq(performance.phase, BrotherPerformance.Phase.IDLE)


func test_pressing_a_direction_starts_with_accel_then_settles_into_run() -> void:
	var performance = BrotherPerformance.new()
	assert_eq(performance.advance(true), BrotherPerformance.ACCEL)
	assert_eq(performance.phase, BrotherPerformance.Phase.ACCEL)
	assert_eq(performance.settled(), BrotherPerformance.RUN)
	assert_eq(performance.phase, BrotherPerformance.Phase.RUN)


func test_letting_go_starts_with_decel_then_settles_back_into_idle() -> void:
	var performance = BrotherPerformance.new()
	performance.advance(true)
	performance.settled()
	assert_eq(performance.advance(false), BrotherPerformance.DECEL)
	assert_eq(performance.settled(), BrotherPerformance.IDLE)
	assert_eq(performance.phase, BrotherPerformance.Phase.IDLE)


func test_holding_a_direction_stays_in_run_without_restarting_accel() -> void:
	var performance = BrotherPerformance.new()
	performance.advance(true)
	performance.settled()
	assert_eq(performance.advance(true), "")
	assert_eq(performance.advance(true), "")
	assert_eq(performance.phase, BrotherPerformance.Phase.RUN)


func test_a_still_brother_asks_for_nothing_rather_than_restarting_idle() -> void:
	var performance = BrotherPerformance.new()
	assert_eq(performance.advance(false), "")
	assert_eq(performance.settled(), "")


func test_a_hit_from_the_front_and_one_from_behind_use_different_frames() -> void:
	var performance = BrotherPerformance.new()
	assert_eq(performance.take_hit(true), BrotherPerformance.HIT_FRONT)
	assert_eq(performance.is_hurting(), true)
	assert_eq(performance.take_hit(false), BrotherPerformance.HIT_BACK)


func test_nothing_else_happens_to_a_brother_while_he_is_hurting() -> void:
	var performance = BrotherPerformance.new()
	performance.advance(true)
	performance.settled()
	performance.take_hit(true)
	assert_eq(performance.advance(true), "")
	assert_eq(performance.advance(false), "")


func test_a_hurting_brother_returns_to_run_when_held_still_and_to_idle_when_not() -> void:
	var running = BrotherPerformance.new()
	running.advance(true)
	running.settled()
	running.advance(true)
	running.take_hit(false)
	assert_eq(running.settled(), BrotherPerformance.RUN)

	var idle = BrotherPerformance.new()
	idle.take_hit(true)
	assert_eq(idle.settled(), BrotherPerformance.IDLE)


func test_input_held_through_a_hit_is_remembered_for_when_the_flinch_ends() -> void:
	var performance = BrotherPerformance.new()
	performance.take_hit(true)
	performance.advance(true)
	assert_eq(performance.settled(), BrotherPerformance.RUN)
	assert_eq(performance.phase, BrotherPerformance.Phase.RUN)


func test_the_animation_names_are_the_ones_the_sheet_is_cut_into() -> void:
	assert_eq(BrotherPerformance.IDLE, &"Idle")
	assert_eq(BrotherPerformance.ACCEL, &"Accel")
	assert_eq(BrotherPerformance.RUN, &"Run")
	assert_eq(BrotherPerformance.DECEL, &"Decel")
	assert_eq(BrotherPerformance.HIT_FRONT, &"Hit_Front")
	assert_eq(BrotherPerformance.HIT_BACK, &"Hit_Back")


func test_the_sheet_is_an_eight_by_seven_grid_of_animations_not_of_directions() -> void:
	var scene: PackedScene = load("res://presentation/brothers/brother.tscn")
	var sprite: Sprite2D = scene.instantiate().get_node("Visuals/Sprite2D")
	assert_eq(sprite.hframes, 8)
	assert_eq(sprite.vframes, 7)
	assert_eq(sprite.rotation, 0.0)
	assert_eq(sprite.position, Vector2(0.0, -48.0))


func test_every_animation_the_brother_asks_for_is_cut_into_the_scene() -> void:
	var root: Node = load("res://presentation/brothers/brother.tscn").instantiate()
	var player: AnimationPlayer = root.get_node("Visuals/Movement")
	for name in [BrotherPerformance.IDLE, BrotherPerformance.ACCEL, BrotherPerformance.RUN,
			BrotherPerformance.DECEL, BrotherPerformance.HIT_FRONT, BrotherPerformance.HIT_BACK]:
		assert_true(player.has_animation(name), "no %s animation in brother.tscn" % name)
	assert_eq(player.get_animation(BrotherPerformance.IDLE).track_get_key_count(0), 6)
	assert_eq(player.get_animation(BrotherPerformance.RUN).track_get_key_count(0), 6)
	assert_eq(player.get_animation(BrotherPerformance.ACCEL).track_get_key_count(0), 3)
	assert_eq(player.get_animation(BrotherPerformance.DECEL).track_get_key_count(0), 3)
	assert_eq(player.get_animation(BrotherPerformance.HIT_FRONT).track_get_key_count(0), 3)
	assert_eq(player.get_animation(BrotherPerformance.HIT_BACK).track_get_key_count(0), 3)


func test_the_first_run_row_and_the_first_idle_row_are_the_ones_the_original_used() -> void:
	var root: Node = load("res://presentation/brothers/brother.tscn").instantiate()
	var player: AnimationPlayer = root.get_node("Visuals/Movement")
	assert_eq(_frames_of(player, BrotherPerformance.IDLE), [0, 1, 2, 3, 4, 5])
	assert_eq(_frames_of(player, BrotherPerformance.RUN), [8, 9, 10, 11, 12, 13])
	assert_eq(_frames_of(player, BrotherPerformance.ACCEL), [16, 17, 18])
	assert_eq(_frames_of(player, BrotherPerformance.DECEL), [24, 25, 26])
	assert_eq(_frames_of(player, BrotherPerformance.HIT_FRONT), [32, 33, 34])
	assert_eq(_frames_of(player, BrotherPerformance.HIT_BACK), [40, 41, 42])


func _frames_of(p_player: AnimationPlayer, p_animation: StringName) -> Array:
	var found: Array = []
	for index in p_player.get_animation(p_animation).track_get_key_count(0):
		found.append(int(p_player.get_animation(p_animation).track_get_key_value(0, index)))
	return found