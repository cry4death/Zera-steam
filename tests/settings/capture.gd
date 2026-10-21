extends SceneTree
## Оконные кадры настоящих экранов; запуск через общую блокировку с --fresh-save.

func _initialize() -> void:
	_run.call_deferred()

func _shot(id: String) -> void:
	await process_frame
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://" + id + ".png")
	print("SETTINGSHOT ", id)

func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event, true)
	await process_frame
	event.pressed = false
	root.push_input(event, true)
	await process_frame

func _button(code: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = code
	event.pressed = true
	root.push_input(event, true)
	await process_frame
	event.pressed = false
	root.push_input(event, true)
	await process_frame

func _run() -> void:
	var meta := root.get_node("Meta")
	meta.persist = false
	meta.settings["fullscreen"] = false
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	root.size = Vector2i(1280, 720)
	meta.finish_first_run()
	set_meta("s6_return_to_base", true)
	change_scene_to_file("res://scenes/base.tscn")
	await create_timer(1.0).timeout
	current_scene._settings_menu.open(true)
	var screen: Control = current_scene._settings_menu._settings
	screen._tab(0)
	screen._activate()
	await _key(KEY_S)
	assert(screen.capture and screen.pending == KEY_S)
	await _key(KEY_ENTER)
	assert(meta.settings["bindings"]["move_up"][0] == KEY_S)
	assert(meta.settings["bindings"]["move_down"][0] == KEY_W)
	await _key(KEY_DELETE)
	assert(meta.settings["bindings"]["move_up"][0] == KEY_W)
	print("SETTINGSINPUT conflict_exchange=true reset=true")
	screen._tab(3)
	await _button(JOY_BUTTON_LEFT_SHOULDER)
	assert(screen.tab == 2)
	await _button(JOY_BUTTON_DPAD_DOWN)
	await _button(JOY_BUTTON_DPAD_LEFT)
	assert(is_equal_approx(meta.settings["music"], 0.95))
	await _button(JOY_BUTTON_DPAD_RIGHT)
	await _button(JOY_BUTTON_B)
	assert(not current_scene._settings_menu.visible)
	current_scene._settings_menu.open(true)
	print("SETTINGSINPUT gamepad_tabs=true gamepad_slider=true gamepad_back=true")
	for i in 3:
		screen._tab(i)
		await _shot(["st1_controls", "st1_screen", "st1_audio"][i])
	meta.set_setting("ui_scale", 1.5)
	screen._tab(0)
	await _shot("st1_controls_150")
	meta.set_setting("ui_scale", 1.0)
	current_scene._settings_menu.close()
	meta.set_setting("ui_scale", 1.5)
	await _shot("st1_base_150")
	meta.set_setting("ui_scale", 1.0)
	meta.set_setting("bindings", SettingsBindings.rebind(SettingsBindings.defaults(), "pause", 0, KEY_P))
	change_scene_to_file("res://scenes/main.tscn")
	await create_timer(1.0).timeout
	var game := current_scene
	await _key(KEY_P)
	assert(game.pause_menu.visible and paused)
	await _key(KEY_P)
	assert(not game.pause_menu.visible and not paused)
	meta.set_setting("bindings", SettingsBindings.defaults())
	print("SETTINGSINPUT rebound_pause_after_scene_change=true")
	game.player.god_mode = true
	game.spawner.enabled = false
	game.radio_t = 0.0
	game.time = 20.0
	game._full_loadout()
	var cards: Array = game.progression.make_cards(0.0)
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(2560, 1080)]:
		root.size = resolution
		await process_frame
		for scale: float in [0.8, 1.5]:
			meta.set_setting("ui_scale", scale)
			game.get_node("HUD/Hud").queue_redraw()
			game.level_up.close()
			paused = false
			await process_frame
			paused = true
			var id := "st1_scale_%d_%dx%d" % [roundi(scale * 100), resolution.x, resolution.y]
			if resolution.x <= 1920:
				await _shot(id + "_hud")
			game.level_up.open(cards)
			if resolution.x <= 1920:
				await _shot(id)
			else:
				await process_frame
				await process_frame
				await process_frame
			for i in cards.size():
				game.level_up._hover = i
				game.level_up._reveal = true
				game.level_up.queue_redraw()
				await process_frame
				await process_frame
				await process_frame
				var rect: Rect2 = game.level_up._rects[i]
				rect = Rect2(rect.position * game.level_up._ui + game.level_up._offset, rect.size * game.level_up._ui)
				if not Rect2(Vector2.ZERO, Vector2(resolution)).encloses(rect):
					push_error("Selected card clipped: " + id + " card=" + str(i) + " rect=" + str(rect))
	print("SETTINGSLAYOUT resolutions=4 scales=2 selected_cards_visible=true")
	game.level_up.close()
	paused = false
	root.size = Vector2i(1280, 720)
	meta.set_setting("ui_scale", 1.5)
	game.pause_menu.open()
	await _shot("st1_pause_150")
	game.pause_menu.close()
	game._open_trader()
	await _shot("st1_trader_150")
	game.trader_ui.close()
	paused = false
	await physics_frame
	await physics_frame
	await physics_frame
	await process_frame
	meta.reset()
	meta.settings["fullscreen"] = false
	var bindings: GDScript = load("res://scripts/ui/settings_bindings.gd")
	meta.settings["bindings"] = bindings.rebind(bindings.defaults(), "move_up", 0, KEY_I)
	meta.apply_settings()
	root.size = Vector2i(1280, 720)
	set_meta("first_run_active", true)
	change_scene_to_file("res://scenes/main.tscn")
	await create_timer(0.5).timeout
	current_scene.player.god_mode = true
	await _shot("st1_hint_rebound")
	print("SETTINGSSHOTS done")
	quit()
