extends GdUnitTestSuite
## Темп за три секунды: события мыши подаются прямо, без доставки ввода headless-окном.

const MODELS := ["ak_s", "pkm", "m134", "butcher"]
const DT := 1.0 / 60.0

class TargetHorde extends Horde:
	func _ready() -> void:
		count = 1
		pos = PackedVector2Array([Vector2(400, 300)])
		dead = PackedByteArray([0])
		uid = PackedInt32Array([1])

	func query_radius(_at: Vector2, _radius: float) -> PackedInt32Array:
		return PackedInt32Array([0])

	func _draw() -> void:
		pass

var _saved_auto: bool


func before_test() -> void:
	_saved_auto = Meta.settings["auto_fire"]
	for action: String in ["aim_left", "aim_right", "aim_up", "aim_down", "aim_override", "fire"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)


func after_test() -> void:
	Meta.settings["auto_fire"] = _saved_auto
	Input.action_release("fire")
	Input.action_release("aim_override")


func _sequence(model: String, auto_fire: bool, moving: bool, override_aim := false, switching := false) -> PackedInt32Array:
	seed(4712)
	Meta.settings["auto_fire"] = auto_fire
	var scene := Node2D.new()
	add_child(scene)
	var player := Player.new()
	player.name = "Player"
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	player.add_child(sprite)
	scene.add_child(player)
	player.set_physics_process(false)
	player.position = Vector2(300, 300)
	var horde := TargetHorde.new()
	scene.add_child(horde)
	horde.set_physics_process(false)
	var weapons := Weapons.new()
	weapons.player = player
	weapons.horde = horde
	scene.add_child(weapons)
	weapons.set_physics_process(false)
	weapons.slots.clear()
	weapons.add_weapon(int(WeaponDefs.MODELS[model]["base"]), model)
	var frames := PackedInt32Array()
	var tick := [0]
	weapons.shot_fired.connect(func(_base: int) -> void: frames.append(tick[0]))
	if not auto_fire:
		Input.action_press("fire")
	for frame in 180:
		tick[0] = frame
		var held := override_aim and (not switching or frame % 60 < 30)
		if held:
			Input.action_press("aim_override")
		else:
			Input.action_release("aim_override")
		var motion := InputEventMouseMotion.new()
		motion.position = player.position + Vector2.from_angle(float(frame) * 0.07 if moving else 0.0) * 100.0
		motion.relative = Vector2(2, 1) if moving else Vector2.ZERO
		player._input(motion)
		player._update_aim()
		player.sprite.rotation = player.aim_dir.angle()
		weapons._update_slot(0, DT)
	Input.action_release("fire")
	Input.action_release("aim_override")
	scene.free()
	return frames


func _check_mode(auto_fire: bool, override_aim := false) -> void:
	for model: String in MODELS:
		var still := _sequence(model, auto_fire, false, override_aim)
		var moving := _sequence(model, auto_fire, true, override_aim)
		print("AIMTEST model=%s auto=%s rmb=%s still=%d moving=%d" % [model, auto_fire, override_aim, still.size(), moving.size()])
		assert_int(still.size()).is_greater(0)
		assert_array(Array(moving)).override_failure_message("%s auto=%s rmb=%s: кадры выстрелов при движении курсора" % [model, auto_fire, override_aim]).is_equal(Array(still))


func test_auto_fire_ignores_mouse_motion() -> void:
	_check_mode(true)


func test_auto_fire_tracks_held_rmb_without_pauses() -> void:
	_check_mode(true, true)


func test_manual_fire_tracks_mouse_without_pauses() -> void:
	_check_mode(false)


func test_rmb_release_resumes_auto_target_on_the_same_cadence() -> void:
	for model: String in MODELS:
		var auto_frames := _sequence(model, true, false)
		var switching := _sequence(model, true, true, true, true)
		print("AIMTEST model=%s auto_frames=%s switching_frames=%s" % [model, auto_frames, switching])
		assert_array(Array(switching)).override_failure_message(model + ": ПКМ не сбивает темп и раскрутку").is_equal(Array(auto_frames))


func test_mouse_motion_and_rmb_preserve_model_bursts() -> void:
	for model: String in ["m4", "an94"]:
		var still := _sequence(model, false, false)
		var moving := _sequence(model, false, true)
		assert_int(still.size()).is_greater(0)
		assert_array(Array(moving)).override_failure_message(model + ": движение мыши сохраняет очередь").is_equal(Array(still))
		var auto_frames := _sequence(model, true, false)
		var switching := _sequence(model, true, true, true, true)
		assert_array(Array(switching)).override_failure_message(model + ": ПКМ сохраняет очередь").is_equal(Array(auto_frames))
