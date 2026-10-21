extends SceneTree
## Стенд базы: --script res://scripts/ui/base_capture.gd -- --fresh-save --shot=<префикс>.
## --capture-before снимает исходные пять экранов; иначе — профили и ввод арсенала.

var base: Control
var prefix := "res://design/tasks/reports/u2"
var failures := 0
var checks := 0

func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok: failures += 1
	print("BASECAPTURE %s %s" % [label, "ok" if ok else "FAIL"])

func _initialize() -> void:
	run.call_deferred()

func settle() -> void:
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw

func shot(suffix: String) -> void:
	await settle()
	var path := prefix + "_" + suffix + ".png"
	var error := root.get_texture().get_image().save_png(path)
	check("screenshot " + suffix, error == OK)
	print("BASECAPTURE shot=%s error=%d" % [path, error])

func run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="): prefix = arg.trim_prefix("--shot=").get_basename()
	var meta := root.get_node("Meta")
	meta.persist = false
	meta.reset()
	set_meta("s6_return_to_base", true)
	base = load("res://scenes/base.tscn").instantiate()
	root.add_child(base)
	current_scene = base
	await settle()
	var before := OS.get_cmdline_user_args().has("--capture-before")
	for i in [4, 3, 2, 1, 0]:
		base._set_tab(i)
		await shot(("before_" if before else "shell_") + ["barracks", "workshop", "arsenal", "crates", "operations"][i])
	if not before:
		base._set_tab(2)
		base._ars_sel = 0
		await shot("arsenal_empty")
		await base._test_click(Vector2(190, 99))
		check("mouse selects locked M4", base._ars_sel == 1)
		base._confirm()
		check("locked model cannot equip", meta.model_for(0) == "ak_s")
		base._msg_t = 0.0
		await shot("arsenal_locked")
		meta.dna_earned = meta.dna_for_level(9) + 60
		meta.dna = 760
		meta.runs = 7
		meta.crates = 3
		meta.military_crates = 1
		meta.tree = {"fire_1": true, "mag_1": true}
		meta.owned.append("m4")
		meta.owned.append("guard")
		meta.owned.append("osa")
		meta.workshop["m4"] = {"damage": 2, "rate": 1, "mag": 1, "reload": 0}
		await shot("arsenal_progress")
		await base._test_click(Vector2(450, 333))
		check("mouse equips M4", meta.model_for(0) == "m4")
		await base._test_key(KEY_LEFT)
		check("keyboard left", base._ars_sel == 0)
		await base._test_key(KEY_RIGHT)
		check("keyboard right", base._ars_sel == 1)
		var pad := InputEventJoypadButton.new()
		pad.button_index = JOY_BUTTON_DPAD_DOWN
		pad.pressed = true
		base._unhandled_input(pad)
		check("gamepad down", base._ars_sel == 3 and base._pad_mode)
		pad.pressed = false
		base._unhandled_input(pad)
		pad.button_index = JOY_BUTTON_DPAD_UP
		pad.pressed = true
		base._unhandled_input(pad)
		check("gamepad up", base._ars_sel == 1)
		pad.pressed = false
		base._unhandled_input(pad)
		base._nav(-1, 0)
		pad.button_index = JOY_BUTTON_A
		pad.pressed = true
		base._unhandled_input(pad)
		check("gamepad A equips AK", meta.model_for(0) == "ak_s")
		pad.pressed = false
		base._unhandled_input(pad)
		base._nav(1, 0)
		await base._test_key(KEY_E)
		check("keyboard E equips M4", meta.model_for(0) == "m4")
		meta.settings["reduce_motion"] = true
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1280, 720))
		root.size = Vector2i(1280, 720)
		base._ars_sel = 1
		await shot("arsenal_720p")
		DisplayServer.window_set_size(Vector2i(1920, 1080))
		root.size = Vector2i(1920, 1080)
		base.hide()
		var sheet := Control.new()
		sheet.set_script(load("res://scripts/ui/style_sheet.gd"))
		root.add_child(sheet)
		sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		await shot("style_sheet")
	print("BASECAPTURE checks=%d failed=%d temporary_save=%s" % [checks, failures, not meta.persist])
	meta.finish_test(0 if failures == 0 else 1)
