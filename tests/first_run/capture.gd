extends SceneTree
## Оконная проверка маршрута и кадров первого запуска; профиль только в памяти.

const DIR := "res://design/tasks/reports/"

func _initialize() -> void:
	_run.call_deferred()


func _shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(DIR + name + ".png")
	print("FIRSTSHOT ", name)


func _run() -> void:
	var meta := root.get_node("Meta")
	meta.persist = false
	meta.reset()
	if OS.get_cmdline_user_args().has("--capture-evac"):
		meta.begin_first_run()
		set_meta("first_run_active", true)
	if OS.get_cmdline_user_args().has("--capture-before"):
		set_meta("s6_return_to_base", true)
	change_scene_to_file("res://scenes/base.tscn")
	await create_timer(2.0).timeout
	if OS.get_cmdline_user_args().has("--capture-before"):
		await _shot("fr1_before_start")
		quit()
		return
	var game := current_scene
	assert(game.first_run)
	assert(game.kills > 0)
	print("FIRST_COMBAT launch_ms=%d game_seconds=%.2f kills=%d" % [Time.get_ticks_msec(), game.time, game.kills])
	var hints := game.get_node("HUD/Hud").get_child(game.get_node("HUD/Hud").get_child_count() - 1)
	if OS.get_cmdline_user_args().has("--capture-evac"):
		game.player.god_mode = true
		game.time = 120.0
		await create_timer(0.1).timeout
		game.gems.count = 0
		game.player.position = hints._shop_at
		await _shot("fr1_hint_evac")
		assert(hints._shop.get_index() < game.horde.get_index())
		print("FIRST_EXIT_VISIBILITY checks=1 failed=0")
		quit()
		return
	await _shot("fr1_first_seconds")
	await _shot("fr1_hint_move")
	var pad := InputEventJoypadMotion.new()
	pad.axis = JOY_AXIS_LEFT_X
	pad.axis_value = 0.4
	Input.parse_input_event(pad)
	await _shot("fr1_hint_move_pad")
	pad.axis_value = 0.0
	Input.parse_input_event(pad)
	var key := InputEventKey.new()
	key.keycode = KEY_D
	key.physical_keycode = KEY_D
	key.pressed = true
	Input.parse_input_event(key)
	await create_timer(0.35).timeout
	key = key.duplicate()
	key.pressed = false
	Input.parse_input_event(key)
	await _shot("fr1_hint_aim")
	# Пропускаем ожидание между эпизодами, сохраняя настоящие системы и сигналы.
	game.player.god_mode = true
	game.time = 8.0
	await create_timer(0.1).timeout
	await _shot("fr1_hint_xp")
	game.player.position = hints._xp_at
	await create_timer(0.8).timeout
	assert(game.level_up.visible)
	await _shot("fr1_first_levelup")
	var card: Dictionary = game.level_up.cards[0]
	game.level_up.chosen.emit(card, game._auto_slot(card))
	game.time = 18.0
	await create_timer(0.15).timeout
	await _shot("fr1_hint_pickup")
	game.player.position = game.pickups._pos[0]
	await create_timer(0.2).timeout
	assert(meta.hint_done("pickup"))
	var aim := InputEventMouseButton.new()
	aim.button_index = MOUSE_BUTTON_RIGHT
	aim.pressed = true
	Input.parse_input_event(aim)
	await create_timer(0.1).timeout
	assert(meta.hint_done("aim"))
	aim = aim.duplicate()
	aim.pressed = false
	Input.parse_input_event(aim)
	game.time = 25.0
	await create_timer(0.1).timeout
	await _shot("fr1_hint_ability")
	game.player.throw_grenade()
	game.time = 65.0
	await create_timer(0.1).timeout
	await _shot("fr1_hint_trader")
	game.player.position = hints._shop_at + Vector2(-110, 0)
	await _interact()
	assert(not meta.hint_done("trader") and not game.trader_ui.visible)
	# Уже изученный торговец доступен при повторе прерванной вылазки.
	meta.complete_hint("trader")
	game.player.position = hints._shop_at
	await _interact()
	assert(game.trader_ui.visible)
	game.trader_ui.visible = false
	paused = false
	game.time = 120.0
	await create_timer(0.1).timeout
	await _shot("fr1_hint_evac")
	game.player.position = hints._exit_at
	await _interact()
	assert(game.results.visible and not meta.needs_first_run())
	await _shot("fr1_results")
	game._return_to_base()
	await create_timer(0.8).timeout
	await _shot("fr1_base_after_first")
	assert(current_scene._tab == 2 and not meta.tab_open(4))
	var old: Dictionary = meta.to_dict()
	old["version"] = 8
	old.erase("first_run")
	assert(meta.from_dict(old))
	set_meta("s6_return_to_base", true)
	change_scene_to_file("res://scenes/base.tscn")
	await create_timer(0.8).timeout
	await _shot("fr1_old_profile_base")
	assert(current_scene._tab == 4 and meta.tab_open(0))
	# Реальный пропуск и страховочное завершение без взаимодействия с выходом.
	meta.reset()
	meta.begin_first_run()
	set_meta("first_run_active", true)
	change_scene_to_file("res://scenes/main.tscn")
	await create_timer(0.8).timeout
	var skip := InputEventKey.new()
	skip.keycode = KEY_TAB
	skip.pressed = true
	Input.parse_input_event(skip)
	await create_timer(0.8).timeout
	assert(not meta.needs_first_run() and meta.runs == 0 and meta.tab_open(4))
	assert(current_scene.scene_file_path == "res://scenes/base.tscn")
	skip = skip.duplicate()
	skip.pressed = false
	Input.parse_input_event(skip)
	meta.reset()
	meta.begin_first_run()
	set_meta("first_run_active", true)
	change_scene_to_file("res://scenes/main.tscn")
	await create_timer(0.8).timeout
	game = current_scene
	game.time = 150.0
	await create_timer(0.2).timeout
	assert(game.results.visible and not meta.needs_first_run() and meta.runs == 1)
	print("FIRST_RUN_INTEGRATION checks=15 failed=0")
	quit()


func _interact() -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_E
	key.physical_keycode = KEY_E
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	key = key.duplicate()
	key.pressed = false
	Input.parse_input_event(key)
	await process_frame
