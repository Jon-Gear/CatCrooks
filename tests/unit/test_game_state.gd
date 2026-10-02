extends "res://addons/gut/test.gd"


func test_a_new_state_opens_a_round_with_two_brothers_alive_and_no_score() -> void:
	var state = GameState.new()
	assert_eq(state.wave_number, 0)
	assert_eq(state.points, 0)
	assert_eq(state.wave_survived, 0)
	assert_eq(state.final_score, 0)
	assert_eq(state.alive_brothers, 2)


func test_reset_round_returns_every_aggregate_to_its_opening_value() -> void:
	var state = GameState.new()
	state.wave_number = 7
	state.points = 3400
	state.wave_survived = 7
	state.final_score = 4100
	state.alive_brothers = 0
	state.reset_round()
	assert_eq(state.wave_number, 0)
	assert_eq(state.points, 0)
	assert_eq(state.wave_survived, 0)
	assert_eq(state.final_score, 0)
	assert_eq(state.alive_brothers, 2)


func test_reset_round_resets_in_place_so_a_held_reference_stays_valid() -> void:
	var state = GameState.new()
	var held_by_a_service = state
	state.wave_number = 3
	state.points = 300
	state.reset_round()
	assert_eq(held_by_a_service.get_instance_id(), state.get_instance_id())
	assert_eq(held_by_a_service.wave_number, 0)
	assert_eq(held_by_a_service.points, 0)


func test_points_and_final_score_are_independent_aggregates() -> void:
	var state = GameState.new()
	state.points = 1200
	state.final_score = 1500
	assert_eq(state.points, 1200)
	assert_eq(state.final_score, 1500)


func test_a_round_written_through_one_reference_reads_back_through_another() -> void:
	var state = GameState.new()
	var wave_service_state = state
	var score_service_state = state
	wave_service_state.wave_number += 1
	wave_service_state.alive_brothers -= 1
	score_service_state.points += 100
	assert_eq(state.wave_number, 1)
	assert_eq(state.alive_brothers, 1)
	assert_eq(state.points, 100)
