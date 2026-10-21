extends Node
## Повторяемый оконный стенд: тот же бой до и после установки связи.

var game: Node
var before := false
var stress := false
var samples: Array[float] = []


func _ready() -> void:
	get_tree().create_timer(60.0, true).timeout.connect(func() -> void: get_tree().quit(1))
	_run.call_deferred()


func _run() -> void:
	before = OS.get_cmdline_user_args().has("--before")
	stress = OS.get_cmdline_user_args().has("--stress")
	Meta.persist = false
	Meta.reset()
	Meta.settings["fullscreen"] = false
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	get_tree().root.size = Vector2i(1280, 720)
	game = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game)
	await get_tree().create_timer(1.0).timeout
	get_tree().paused = true
	seed(92027)
	game.spawner.enabled = false
	game.player.god_mode = true
	game.player.position = Vector2(1200, 900)
	game.player.aim_dir = Vector2.RIGHT
	game.player.sprite.rotation = 0.0
	game.camera.target = null
	game.camera.position_smoothing_enabled = false
	game.camera.position = game.player.position
	game.camera.zoom = Vector2(3, 3)
	game.camera.shake_multiplier = 0.0
	var layout: Array[Dictionary] = []
	if not stress: game.obstacles.setup(game.obstacles.arena, layout)
	game.weapons.slots.clear()
	game.weapons._weapon_uid = 0
	for model in ["mosin", "butcher", "ppsh", "lpo"]:
		game.weapons.add_weapon(WeaponDefs.MODELS[model]["base"], model)
	game.weapons.bonuses = {}
	for i in 4:
		game.weapons.refresh(i)
		game.weapons.slots[i].angle = 0.0
		game.weapons.slots[i].aimed = true
	game.horde.count = 0
	for k in 500:
		var a := k * 2.399963
		var r := 105.0 + sqrt(float(k)) * 9.0
		game.horde.spawn(game.player.position + Vector2.from_angle(a) * r, k % 4)
	game.horde._rebuild_grid()
	game.horde.pos[0] = game.player.position + Vector2(210, -5)
	game.horde.hp[0] = 10.0
	for k in range(1, 8):
		game.horde.pos[k] = game.player.position + Vector2.from_angle((k - 4) * 0.14) * 68
		game.horde.hp[k] = 60.0
		game.horde.max_hp[k] = 60.0
	game.horde._rebuild_grid()
	game.horde._render()
	game.weapons._update_gun_layers()
	if stress:
		if not before: game.weapons.install_link(1, 0)
		game.weapons.slots[2].ammo = WeaponDefs.Ammo.CRYO
		game.weapons.slots[2].ammo_rank = 3
		game.weapons.refresh(2)
		game._bench_t = 0.0
		game.player.force_auto_aim = true
		game.player.autopilot = true
		game.camera.target = game.player
		game.tree_exiting.connect(_stress_result)
		get_tree().paused = false
		return
	if not before: game.weapons.install_link(1, 0)
	for aim in 3:
		game.weapons.slots[0].angle = (game.horde.pos[0] - game.weapons.gun_point(0, game.weapons.slots[0].muzzle)).angle()
	game.weapons._fire_shot(0, game.weapons.slots[0], 0)
	for frame in 45: game.weapons._update_bullets(1.0 / 120.0)
	game.weapons._update_links(0.18)
	game.weapons._age_fx(0.18)
	game.effects._update_lights(0.18)
	if not before:
		await shot("build_heavy_battery")
	game.weapons._fire_shot(1, game.weapons.slots[1], 4)
	for frame in 6: game.weapons._update_bullets(1.0 / 120.0)
	game.weapons._update_links(0.14)
	game.weapons._age_fx(0.14)
	game.effects._update_lights(0.14)
	game.horde._render()
	game.weapons._update_gun_layers()
	if before:
		await shot("overflow_fight_before")
	else:
		await shot("overflow_fight")
		var screen := get_tree().root.get_texture().get_image()
		for y in screen.get_height():
			for x in screen.get_width():
				var c := screen.get_pixel(x, y)
				var v := c.get_luminance()
				screen.set_pixel(x, y, Color(v, v, v, c.a))
		screen.save_png("res://design/tasks/reports/sy2_gray.png")
		game.weapons.slots[1].modules.clear()
		game.level_up.open([{"type": "link", "id": WeaponDefs.Module.LINK, "rare": false}, {"type": "passive", "id": WeaponDefs.Passive.DAMAGE, "rare": false}, {"type": "module", "id": WeaponDefs.Module.TWIN, "rare": false}])
		await shot("card_overflow")
	if OS.get_cmdline_user_args().has("--video"):
		game.level_up.close()
		# Сохраняем четыре заданных ствола: опыт не меняет комплект посреди видеопрохода.
		game.progression.level_ready.disconnect(game._on_level_ready)
		game._bench = true # общий режим не открывает карты поверх записываемого боя
		game._bench_t = 0.0
		game.weapons.install_link(1, 0)
		game.weapons.slots[2].ammo = WeaponDefs.Ammo.CRYO
		game.weapons.slots[2].ammo_rank = 3
		game.weapons.refresh(2)
		game.player.force_auto_aim = true
		game.player.autopilot = true
		game.camera.target = game.player
		game.spawner.enabled = true
		game.spawner.time = 480.0
		get_tree().paused = false
		await get_tree().create_timer(8.0).timeout
	print("SYNERGY_SHOTS before=%s enemies=%d" % [before, game.horde.count])
	game.weapons.clear_projectiles()
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit()


func _process(delta: float) -> void:
	if stress and game != null and not get_tree().paused and game._bench_t > 3.0:
		samples.append(delta * 1000.0)


func _stress_result() -> void:
	samples.sort()
	if samples.is_empty(): return
	print("SYNERGY_STRESS before=%s frames=%d p50=%.2f p95=%.2f p99=%.2f metrics=%s" % [before, samples.size(), samples[int(samples.size() * 0.50)], samples[mini(samples.size() - 1, int(samples.size() * 0.95))], samples[mini(samples.size() - 1, int(samples.size() * 0.99))], JSON.stringify(game.weapons.link_metrics)])


func shot(suffix: String) -> void:
	game.weapons.queue_redraw()
	await get_tree().create_timer(0.15, true).timeout
	await RenderingServer.frame_post_draw
	get_tree().root.get_texture().get_image().save_png("res://design/tasks/reports/sy2_%s.png" % suffix)
