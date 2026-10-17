extends SceneTree
## Снимки настоящего игрового фона и проверка альфы отдельного оверлея.

var _output := "C:/Users/Dev/Desktop/GameZ/tasks/inbox/G2"
var _failures := 0


func _initialize() -> void:
	root.visible = false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_output = arg.trim_prefix("--out=")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		_failures += 1
		push_error("FAIL: " + message)


func _render_frames() -> void:
	await process_frame
	RenderingServer.force_draw(false)
	await process_frame
	RenderingServer.force_draw(false)


func _save(view: SubViewport, name: String) -> void:
	await _render_frames()
	var image := view.get_texture().get_image()
	if image == null or image.is_empty():
		_check(false, "readback " + name)
		return
	var error := image.save_png(_output.path_join(name + ".png"))
	_check(error == OK, "saved " + name + ".png")


func _check_alpha(alarm: AlarmOverlay, view: SubViewport, label: String) -> void:
	await _render_frames()
	var image := view.get_texture().get_image()
	if image == null or image.is_empty():
		_check(false, "alpha readback " + label)
		return
	var maximum := 0.0
	for y in range(int(view.size.y * 0.2), int(view.size.y * 0.8), 3):
		for x in range(int(view.size.x * 0.2), int(view.size.x * 0.8), 3):
			maximum = maxf(maximum, image.get_pixel(x, y).a)
	print("ALPHA: ", label, "; central_max=", maximum, "; edge=", alarm._edge_alpha)
	_check(maximum <= 0.12, "central 60 percent alpha <= 0.12: " + label)


func _run() -> void:
	seed(222)
	var view := SubViewport.new()
	view.size = Vector2i(1920, 1080)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game: Node2D = scene.instantiate()
	game.process_mode = Node.PROCESS_MODE_DISABLED
	view.add_child(game)
	var player: Player = game.get("player")
	var horde: Horde = game.get("horde")
	var floor_layer: FloorDecals = game.get("floor_decals")
	var camera: GameCamera = game.get("camera")
	player.god_mode = true
	for i in 130:
		var p := player.position + Vector2(randf_range(-300.0, 300.0), randf_range(-145.0, 145.0))
		if p.distance_to(player.position) > 18.0:
			horde.spawn(p)
	for i in 28:
		var p := player.position + Vector2(randf_range(-280.0, 280.0), randf_range(-130.0, 130.0))
		floor_layer.blood(PixelArt.tex("blood_%d" % (i % 8)), p, randf() * TAU, randf_range(0.7, 1.5))
	horde._physics_process(0.0)
	floor_layer._process(0.0)
	camera.global_position = player.global_position
	camera.position_smoothing_enabled = false
	game.get_node("HUD/Hud").set("show_debug", false)
	var layer := CanvasLayer.new()
	layer.layer = 4
	game.add_child(layer)
	var alarm := AlarmOverlay.new()
	layer.add_child(alarm)
	alarm.warn(3.0)
	alarm.set_process(false)
	alarm._process(0.6)
	await _save(view, "warn")
	alarm.start(30.0)
	alarm.set_process(false)
	alarm._process(7.81)
	await _save(view, "start")
	alarm.finish()
	alarm.set_process(false)
	alarm._process(0.2)
	await _save(view, "finish")
	alarm.stop()
	await _save(view, "background")
	# Отдельный прозрачный viewport позволяет измерить альфу всех элементов.
	var alpha_view := SubViewport.new()
	alpha_view.size = Vector2i(1920, 1080)
	alpha_view.transparent_bg = true
	alpha_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(alpha_view)
	var probe := AlarmOverlay.new()
	alpha_view.add_child(probe)
	probe.warn(3.0)
	probe.set_process(false)
	probe._process(0.6)
	await _check_alpha(probe, alpha_view, "warn")
	probe.start(30.0)
	probe.set_process(false)
	await _check_alpha(probe, alpha_view, "start flash")
	probe._process(0.11)
	await _check_alpha(probe, alpha_view, "start first heartbeat")
	probe._process(7.7)
	await _check_alpha(probe, alpha_view, "start steady")
	probe.finish()
	probe.set_process(false)
	probe._process(0.2)
	await _check_alpha(probe, alpha_view, "finish")
	alpha_view.size = Vector2i(1280, 720)
	probe.start(30.0)
	probe.set_process(false)
	probe._process(1.1)
	await _check_alpha(probe, alpha_view, "1280x720")
	alpha_view.size = Vector2i(2560, 1440)
	await _check_alpha(probe, alpha_view, "2560x1440")
	print("RESULT: failures=", _failures)
	quit(0 if _failures == 0 else 1)
