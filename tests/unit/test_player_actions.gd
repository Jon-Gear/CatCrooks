extends "res://addons/gut/test.gd"


func test_player_one_drives_the_first_gamepad_and_player_two_drives_the_second() -> void:
	assert_eq(PlayerActions.new(1).gamepad_device, 0)
	assert_eq(PlayerActions.new(2).gamepad_device, 1)


func test_every_action_is_named_for_the_brother_it_belongs_to() -> void:
	var one = PlayerActions.new(1)
	var two = PlayerActions.new(2)
	assert_eq(one.move_left, &"p1_move_left")
	assert_eq(one.move_right, &"p1_move_right")
	assert_eq(one.move_up, &"p1_move_up")
	assert_eq(one.move_down, &"p1_move_down")
	assert_eq(one.fire, &"p1_fire")
	assert_eq(one.previous_weapon, &"p1_prev_weapon")
	assert_eq(one.next_weapon, &"p1_next_weapon")
	assert_eq(two.move_left, &"p2_move_left")
	assert_eq(two.move_up, &"p2_move_up")
	assert_eq(two.fire, &"p2_fire")
	assert_eq(two.previous_weapon, &"p2_prev_weapon")
	assert_eq(two.next_weapon, &"p2_next_weapon")


func test_the_two_brothers_never_share_a_move_or_weapon_action() -> void:
	var one = PlayerActions.new(1)
	var two = PlayerActions.new(2)
	for mine in [one.move_left, one.move_right, one.move_up, one.move_down, one.fire, one.previous_weapon, one.next_weapon]:
		for theirs in [two.move_left, two.move_right, two.move_up, two.move_down, two.fire, two.previous_weapon, two.next_weapon]:
			assert_ne(mine, theirs)


func test_pause_is_the_one_action_both_brothers_share() -> void:
	assert_eq(PlayerActions.new(1).pause, PlayerActions.new(2).pause)
	assert_eq(PlayerActions.new(1).pause, &"pause")


func test_every_action_the_brothers_reach_for_is_a_real_action_in_the_project() -> void:
	for player_number in [1, 2]:
		for action in PlayerActions.new(player_number).every_action():
			assert_true(InputMap.has_action(action), "%s is not in the input map" % action)


func test_brother_one_moves_on_the_arrow_keys_and_brother_two_on_wasd() -> void:
	assert_true(_binds_key(&"p1_move_left", KEY_LEFT))
	assert_true(_binds_key(&"p1_move_right", KEY_RIGHT))
	assert_true(_binds_key(&"p1_move_up", KEY_UP))
	assert_true(_binds_key(&"p1_move_down", KEY_DOWN))
	assert_true(_binds_key(&"p2_move_left", KEY_A))
	assert_true(_binds_key(&"p2_move_right", KEY_D))
	assert_true(_binds_key(&"p2_move_up", KEY_W))
	assert_true(_binds_key(&"p2_move_down", KEY_S))


func test_brother_one_cycles_weapons_on_the_comma_and_full_stop_keys() -> void:
	assert_true(_binds_key(&"p1_prev_weapon", KEY_COMMA))
	assert_true(_binds_key(&"p1_next_weapon", KEY_PERIOD))


func test_brother_two_cycles_weapons_on_q_and_e() -> void:
	assert_true(_binds_key(&"p2_prev_weapon", KEY_Q))
	assert_true(_binds_key(&"p2_next_weapon", KEY_E))


func test_either_brother_can_pause() -> void:
	assert_true(_binds_key(&"pause", KEY_ESCAPE))


func test_a_left_arrow_press_reaches_brother_one_and_never_brother_two() -> void:
	assert_true(_matches_action(KEY_LEFT, &"p1_move_left"))
	assert_false(_matches_action(KEY_LEFT, &"p2_move_left"))


func test_an_a_press_reaches_brother_two_and_never_brother_one() -> void:
	assert_true(_matches_action(KEY_A, &"p2_move_left"))
	assert_false(_matches_action(KEY_A, &"p1_move_left"))


func _binds_key(action: StringName, keycode: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode == keycode:
			return true
	return false


func _matches_action(keycode: int, action: StringName) -> bool:
	var press := InputEventKey.new()
	press.device = -1
	press.physical_keycode = keycode
	press.pressed = true
	return InputMap.event_is_action(press, action)
