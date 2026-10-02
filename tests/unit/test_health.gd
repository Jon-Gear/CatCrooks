extends "res://addons/gut/test.gd"


func test_new_health_starts_full_at_max() -> void:
	var health = Health.new(100.0)
	assert_eq(health.current, 100.0)
	assert_eq(health.max_health, 100.0)
	assert_true(health.is_full())
	assert_false(health.is_empty())


func test_damage_reduces_current_and_reports_what_it_took() -> void:
	var health = Health.new(100.0)
	var taken = health.apply_damage(30.0)
	assert_eq(taken, 30.0)
	assert_eq(health.current, 70.0)


func test_damage_beyond_the_last_health_clamps_at_zero() -> void:
	var health = Health.new(10.0)
	var taken = health.apply_damage(25.0)
	assert_eq(taken, 10.0)
	assert_eq(health.current, 0.0)
	assert_true(health.is_empty())


func test_damage_on_empty_health_takes_nothing() -> void:
	var health = Health.new(10.0)
	health.apply_damage(25.0)
	var taken = health.apply_damage(5.0)
	assert_eq(taken, 0.0)
	assert_eq(health.current, 0.0)


func test_damage_of_zero_or_less_is_a_no_op() -> void:
	var health = Health.new(100.0)
	assert_eq(health.apply_damage(0.0), 0.0)
	assert_eq(health.apply_damage(-10.0), 0.0)
	assert_eq(health.current, 100.0)


func test_heal_restores_health_and_reports_how_much() -> void:
	var health = Health.new(100.0)
	health.apply_damage(30.0)
	var healed = health.heal(20.0)
	assert_eq(healed, 20.0)
	assert_eq(health.current, 90.0)


func test_heal_never_pushes_past_max() -> void:
	var health = Health.new(100.0)
	health.apply_damage(10.0)
	var healed = health.heal(50.0)
	assert_eq(healed, 10.0)
	assert_eq(health.current, 100.0)
	assert_true(health.is_full())


func test_heal_on_full_health_restores_nothing() -> void:
	var health = Health.new(100.0)
	assert_eq(health.heal(20.0), 0.0)
	assert_eq(health.current, 100.0)


func test_heal_of_zero_or_less_is_a_no_op() -> void:
	var health = Health.new(100.0)
	health.apply_damage(30.0)
	assert_eq(health.heal(0.0), 0.0)
	assert_eq(health.heal(-20.0), 0.0)
	assert_eq(health.current, 70.0)


func test_fill_restores_a_downed_health_to_full() -> void:
	var health = Health.new(100.0)
	health.apply_damage(100.0)
	assert_true(health.is_empty())
	health.fill()
	assert_eq(health.current, 100.0)
	assert_false(health.is_empty())


func test_a_sequence_of_hits_keeps_current_inside_its_bounds() -> void:
	var health = Health.new(100.0)
	health.apply_damage(25.0)
	health.heal(20.0)
	health.apply_damage(1000.0)
	health.heal(1000.0)
	assert_eq(health.current, 100.0)
	assert_false(health.current < 0.0)
