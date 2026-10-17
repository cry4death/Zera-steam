extends SceneTree

var fired := 0
var burst := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	seed(777)
	var game := load("res://scenes/main.tscn").instantiate() as Node2D
	root.add_child(game)
	Engine.time_scale = 1.0
	var h: Horde = game.get_node("World/Horde")
	var player: Player = game.get_node("World/Player")
	player.autopilot = false
	game.get_node("Spawner").enabled = false
	game.get_node("World/Weapons").process_mode = Node.PROCESS_MODE_DISABLED
	h.spit_fired.connect(func(_from: Vector2, _to: Vector2, _damage: float) -> void: fired += 1)
	h.fat_burst.connect(func(_pos: Vector2, _elite: bool) -> void: burst += 1)
	for code in [KEY_F7, KEY_F8, KEY_F9, KEY_F10]:
		var key := InputEventKey.new()
		key.keycode = code
		key.pressed = true
		game._unhandled_input(key)
	print("S1 DEBUG F7/F8/F9/F10 enemies=%d expected=13" % h.count)
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/Dev/Desktop/GameZ/tasks/reports/s1_types.png")
	await create_timer(3.0).timeout
	var index := -1
	for i in h.count:
		if h.kind[i] == Horde.Kind.FAT and h.elite[i] == 0:
			index = i
	if index >= 0:
		h.damage(index, 9999.0, Vector2.RIGHT, 0.0)
	await create_timer(0.08).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/Dev/Desktop/GameZ/tasks/reports/s1_fat.png")
	print("S1 DEBUG spit_fired=%d fat_burst=%d fps=%d" % [fired, burst, Engine.get_frames_per_second()])
	quit(0 if fired > 0 and burst == 1 else 1)
