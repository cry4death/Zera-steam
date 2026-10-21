extends GdUnitTestSuite
## ST1: профиль, обмен клавиш и независимость выключателей.

var _snapshot: Dictionary
var _persist: bool
var _path: String

func before_test() -> void:
	_snapshot = Meta.to_dict().duplicate(true)
	_persist = Meta.persist
	_path = Meta.save_path
	Meta.persist = false
	Meta.reset()

func after_test() -> void:
	Meta.from_dict(_snapshot)
	Meta.apply_settings()
	Meta.persist = _persist
	Meta.save_path = _path

func test_safe_defaults_and_limits() -> void:
	var defaults := Meta.clean_settings({})
	assert_float(defaults["ui_scale"]).is_equal(1.0)
	assert_bool(defaults["screen_flashes"]).is_true()
	assert_bool(defaults["screen_blood"]).is_true()
	assert_bool(defaults["alarm_blink"]).is_true()
	assert_dict(defaults["bindings"]).is_equal(SettingsBindings.defaults())
	assert_dict(defaults).is_equal(Meta.DEFAULT_SETTINGS)
	var dirty := Meta.clean_settings({"ui_scale": 9.0, "shake": -1, "camera_recoil": NAN, "screen_blood": 0, "bindings": {"dash": [0, "X", -30]}})
	assert_float(dirty["ui_scale"]).is_equal(1.5)
	assert_float(dirty["shake"]).is_equal(0.0)
	assert_float(dirty["camera_recoil"]).is_equal(1.0)
	assert_bool(dirty["screen_blood"]).is_true()
	assert_array(dirty["bindings"]["dash"]).is_equal([KEY_SPACE, KEY_SHIFT])
	assert_float(Meta.clean_settings({"ui_scale": 0.0})["ui_scale"]).is_equal(0.8)

func test_conflict_exchanges_last_binding_and_preserves_alternatives() -> void:
	var bindings := SettingsBindings.defaults()
	assert_array(SettingsBindings.conflicts(bindings, "reload", KEY_Q)).is_equal(["grenade"])
	var changed := SettingsBindings.rebind(bindings, "reload", 0, KEY_Q)
	assert_array(changed["reload"]).is_equal([KEY_Q])
	assert_array(changed["grenade"]).is_equal([KEY_R, KEY_G, -MOUSE_BUTTON_MIDDLE])
	assert_array(bindings["reload"]).is_equal([KEY_R])
	changed = SettingsBindings.rebind(changed, "fire", 0, -MOUSE_BUTTON_RIGHT)
	assert_array(changed["fire"]).is_equal([-MOUSE_BUTTON_RIGHT])
	assert_array(changed["aim_override"]).is_equal([-MOUSE_BUTTON_LEFT])
	changed = SettingsBindings.rebind(changed, "dash", 0, KEY_SHIFT)
	assert_array(changed["dash"]).is_equal([KEY_SHIFT, KEY_SPACE])

func test_inputmap_restores_keyboard_mouse_and_keeps_gamepad() -> void:
	var changed := SettingsBindings.rebind(SettingsBindings.defaults(), "reload", 0, KEY_T)
	changed = SettingsBindings.rebind(changed, "pause", 0, -MOUSE_BUTTON_XBUTTON1)
	SettingsBindings.apply(changed)
	SettingsBindings.apply(changed)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_T
	assert_bool(InputMap.event_is_action(key, "reload")).is_true()
	key.physical_keycode = KEY_R
	assert_bool(InputMap.event_is_action(key, "reload")).is_false()
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_XBUTTON1
	assert_bool(InputMap.event_is_action(mouse, "pause")).is_true()
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_X
	assert_bool(InputMap.event_is_action(pad, "reload")).is_true()
	assert_int(InputMap.action_get_events("reload").size()).is_equal(2)

func test_saved_profile_roundtrip_and_actual_hints() -> void:
	Meta.settings["bindings"] = SettingsBindings.rebind(SettingsBindings.defaults(), "grenade", 0, KEY_T)
	Meta.settings["ui_scale"] = 1.5
	Meta.settings["screen_blood"] = false
	Meta.settings["screen_flashes"] = false
	Meta.settings["alarm_blink"] = false
	Meta.settings["shake"] = 0.0
	Meta.settings["camera_recoil"] = 0.75
	Meta.save_path = "res://tmp/st1_profile_test.json"
	Meta.persist = true
	Meta.save()
	Meta.reset()
	assert_bool(Meta.load_save()).is_true()
	assert_str(SettingsBindings.hint("grenade")).is_equal("T")
	assert_float(Meta.settings["ui_scale"]).is_equal(1.5)
	assert_bool(Meta.settings["screen_blood"]).is_false()
	assert_bool(Meta.settings["screen_flashes"]).is_false()
	assert_bool(Meta.settings["alarm_blink"]).is_false()
	assert_float(Meta.settings["shake"]).is_equal(0.0)
	assert_float(Meta.settings["camera_recoil"]).is_equal(0.75)
	DirAccess.remove_absolute(Meta.save_path)
	Meta.persist = false

func test_old_profiles_keep_progress_and_fr1(version: int, test_parameters := [[1], [8], [9]]) -> void:
	Meta.dna = 321
	Meta.dna_earned = 500
	Meta.crates = 4
	Meta.military_crates = 2
	Meta.runs = 7
	Meta.complete_hint("move")
	var old := Meta.to_dict().duplicate(true)
	old["version"] = version
	old["settings"] = {"master": 0.35, "shake": 0.0, "reduce_motion": true, "auto_fire": false}
	Meta.reset()
	assert_bool(Meta.from_dict(old)).is_true()
	assert_int(Meta.dna).is_equal(321)
	assert_int(Meta.crates).is_equal(4)
	assert_int(Meta.runs).is_equal(7)
	assert_dict(Meta.to_dict()["campaign"]).is_equal(old["campaign"])
	assert_float(Meta.settings["master"]).is_equal(0.35)
	assert_float(Meta.settings["shake"]).is_equal(0.0)
	assert_bool(Meta.settings["reduce_motion"]).is_true()
	assert_bool(Meta.settings["auto_fire"]).is_false()
	assert_dict(Meta.settings["bindings"]).is_equal(SettingsBindings.defaults())
	if version == 9:
		assert_dict(Meta.first_run).is_equal(old["first_run"])
	else:
		assert_bool(Meta.first_run["done"]).is_true()

func test_audio_effects_do_not_mute_music_or_interface() -> void:
	Meta.set_setting("effects", 0.0)
	assert_bool(AudioServer.is_bus_mute(AudioServer.get_bus_index("Weapons"))).is_true()
	assert_bool(AudioServer.is_bus_mute(AudioServer.get_bus_index("Shots"))).is_true()
	assert_bool(AudioServer.is_bus_mute(AudioServer.get_bus_index("World"))).is_true()
	assert_bool(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music"))).is_false()
	assert_bool(AudioServer.is_bus_mute(AudioServer.get_bus_index("UI"))).is_false()
	Meta.set_setting("effects", 1.0)
	Meta.set_setting("ui", 0.0)
	assert_bool(AudioServer.is_bus_mute(AudioServer.get_bus_index("UI"))).is_true()
	assert_bool(AudioServer.is_bus_mute(AudioServer.get_bus_index("Weapons"))).is_false()

func test_camera_shake_and_recoil_are_independent() -> void:
	var camera := GameCamera.new()
	Meta.settings["camera_recoil"] = 1.0
	camera.shake_multiplier = 0.0
	camera.shake(30.0)
	camera.kick(Vector2.RIGHT, 2.0)
	camera._process(0.0)
	assert_vector(camera.offset).is_equal(Vector2(-2, 0))
	Meta.settings["camera_recoil"] = 0.0
	camera._process(0.0)
	assert_vector(camera.offset).is_equal(Vector2.ZERO)
	camera.shake_multiplier = 0.1
	camera._process(0.0)
	assert_float(camera.offset.length()).is_less_equal(0.40001)
	camera.free()

func test_screen_blood_can_be_disabled_without_reducing_world_gore() -> void:
	var blood: Control = load("res://scripts/screen_blood.gd").new()
	Meta.settings["gore"] = 2
	Meta.settings["screen_blood"] = false
	blood.splash(1.0)
	assert_int(blood._pos.size()).is_equal(0)
	assert_float(Meta.gore_multiplier()).is_equal(1.0)
	Meta.settings["gore"] = 0
	Meta.settings["screen_blood"] = true
	blood.gore_multiplier = Meta.gore_multiplier()
	blood.splash(1.0)
	assert_int(blood._pos.size()).is_greater(0)
	blood.free()
