class_name BossShots
extends RefCounted
## Воспроизводимая съёмка настоящего viewport: фазы, границы атак, кровь и глобус.


static func save(game: Node, path: String) -> void:
	await game.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var err := game.get_viewport().get_texture().get_image().save_png(path)
	if err != OK:
		push_error("BOSSSHOTS save failed: " + path)
	print("BOSSSHOTS ", path)


static func run(game: Node) -> void:
	game.set_physics_process(false)
	game.set_process(false)
	game.spawner.enabled = false
	game.weapons.firing_enabled = false
	game.player.set_physics_process(false)
	game.horde.set_physics_process(false)
	game.activities.enabled = false
	game.time = 620.0
	game.trader_visit = game.TRADER_TIMES.size()
	game._boss_spawned = true
	game.radio_text = ""
	game.radio_t = 0.0
	game.player.god_mode = true
	game.get_node("HUD/Hud").show_debug = false
	var center: Vector2 = game.ARENA.get_center() + Vector2(0, -100)
	game.player.position = center + Vector2(145, 42)
	game.camera.position = center + Vector2(60, 10)
	game.camera.set_process(false)
	game.camera.set_physics_process(false)
	var prefix := "res://design/tasks/reports/b2_"
	var selected_kind := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--boss-kind="):
			selected_kind = arg.trim_prefix("--boss-kind=")
		if arg.begins_with("--shot="):
			prefix = arg.trim_prefix("--shot=").get_basename() + "_"
	var original: Boss = game.boss
	original.visible = false
	if selected_kind == "hive_heart":
		await _heart(game, original, prefix)
		print("BOSSSHOTS complete=true viewport=true")
		return
	if selected_kind == "general":
		await _general(game, original, prefix)
		print("BOSSSHOTS complete=true viewport=true")
		return
	for kind in [BossHive.Hive.MOTHER, BossHive.Hive.MEAT]:
		if not selected_kind.is_empty() and selected_kind != ("mother" if kind == BossHive.Hive.MOTHER else "meat_mountain"):
			continue
		var b := BossTest.make_boss(game, kind)
		b.effects = game.effects
		b.floor_decals = game.floor_decals
		game.boss = b
		b.start(center)
		var name := "mother" if kind == BossHive.Hive.MOTHER else "meat"
		for phase in [1, 2, 3]:
			b.phase = phase
			b.hp = b.max_hp * [1.0, 0.60, 0.25][phase - 1]
			b._flash = 0.0
			if kind == BossHive.Hive.MOTHER:
				for k in 4:
					b._sacs[k] = 0.0 if k < phase - 1 else BossHive.SAC_HP
				if phase >= 2:
					b._sacs[phase - 1] = BossHive.SAC_HP * 0.4
				b._marks.clear()
				b._mark_age.clear()
				b._mark_kind.clear()
				b._mark_hit.clear()
				b._mark_origin.clear()
				b._begin_mark(game.player.position, BossHive.Attack.TENTACLE)
				b._mark_age[0] = 0.72
				if phase >= 2:
					b._begin_mark(game.player.position + Vector2(0, -62), BossHive.Attack.TENTACLE)
					b._mark_age[1] = 1.12 # Сам удар рядом с сохраняющимся предупреждением.
				if phase == 3:
					b._begin_mark(game.player.position + Vector2(65, 40), BossHive.Attack.BIOMASS)
					b._mark_age[2] = 0.8
				b._birth_age = 0.9
			else:
				b._begin_roll()
				b._roll_age = 0.55
				if phase < 3:
					b._begin_mark(center + Vector2(-60, 40), BossHive.Attack.ROT)
					b._mark_age[b._mark_age.size() - 1] = 1.4
			b.queue_redraw()
			game.get_node("HUD/Hud").queue_redraw()
			await save(game, prefix + name + "_%d.png" % phase)
		# Общий R1c/R1d death handler плюс собственный останок.
		if not selected_kind.is_empty():
			b.free()
			continue
		b.take_damage(999999.0, Vector2.LEFT, center)
		game.gore.boss_burst(center)
		await game.get_tree().create_timer(0.8).timeout
		await save(game, prefix + "death_" + name + ".png")
		b.free()
	game.boss = original
	if not selected_kind.is_empty():
		print("BOSSSHOTS complete=true viewport=true")
		return
	# Глобус и брифинг используют действующие данные, только профиль в памяти.
	var state := CampaignRules.initial(812)
	state["turn"] = 4
	state["war"]["front"] = {}
	state["nests"]["mother"]["discovered"] = true
	state["nests"]["meat_mountain"]["discovered"] = true
	state["offers"] = CampaignDirector.generate(state)
	Meta.campaign = state
	var base := load("res://scenes/base.tscn").instantiate() as Control
	game.get_tree().set_meta("s6_return_to_base", true)
	var layer := CanvasLayer.new()
	layer.layer = 100
	game.get_tree().root.add_child(layer)
	game.get_node("HUD").visible = false
	game.get_node("Overlay").visible = false
	layer.add_child(base)
	base._tab = base.Tab.OPERATIONS
	base._open_operations()
	base._select_region("siberia")
	base._globe.skip_motion()
	base.queue_redraw()
	await game.get_tree().create_timer(0.4).timeout
	await save(game, prefix + "globe.png")
	base.free()
	layer.free()
	print("BOSSSHOTS complete=true viewport=true")


static func _heart(game: Node, original: Boss, prefix: String) -> void:
	var b := BossHeart.new()
	game.get_node("World").add_child(b)
	b.set_physics_process(false)
	b.player = game.player
	b.horde = game.horde
	b.obstacles = game.obstacles
	b.effects = game.effects
	b.floor_decals = game.floor_decals
	b.camera = game.camera
	b.sfx = game.sfx
	b.arena = game.ARENA
	game.boss = b
	b.start(game.ARENA.get_center())
	game.get_node("World/Ground").z_index = -2
	game.obstacles.hive_skin = PixelArt.tex("hive_wall")
	game.obstacles.queue_redraw()
	game.player.position = game.obstacles.free_point(b.position + Vector2(165, 80), Player.RADIUS)
	game.camera.position = b.position
	game.camera.reset_smoothing()
	b._summon()
	# Замороженная орда тоже должна передать позиции нового выводка в MultiMesh.
	game.horde._physics_process(1.0 / 60.0)
	for phase in [1, 2, 3, 4]:
		b.phase = phase
		b.hp = b.max_hp * [1.0, 0.65, 0.3, 0.08][phase - 1]
		b._cage_half = BossHeart.HALF[phase - 1]
		b._time = 1.2
		b._clear_attacks()
		b._sequence = 1
		b._begin_attack(game.player.position, BossHeart.Attack.WAVE)
		b._ages[0] = 2.65
		b._begin_attack(game.player.position + Vector2(0, -60), BossHeart.Attack.WHIP)
		b._ages[1] = 0.8
		if phase >= 2:
			b._begin_attack(game.player.position + Vector2(-60, 25), BossHeart.Attack.ACID)
			b._ages[2] = 1.1
		if phase >= 3:
			b._begin_attack(game.player.position + Vector2(35, -105), BossHeart.Attack.ACID)
			b._ages[3] = 2.0
		b._flash = 0.0
		b.queue_redraw()
		b._walls.queue_redraw()
		game.get_node("HUD/Hud").queue_redraw()
		await save(game, prefix + "arena_%d.png" % phase)
	await save(game, prefix + "arena.png")
	b.take_damage(999999, Vector2.LEFT, b.position)
	game.gore.boss_burst(b.position)
	# В обычном бою обработчик смерти Сердца разрывает выводок вокруг органа.
	var previous: int = game.horde.death_override
	game.horde.death_override = Gore.Death.GIBS
	for i: int in game.horde.query_radius(b.position, 200.0):
		if game.horde.dead[i] == 0:
			game.horde.damage(i, 99999.0, (game.horde.pos[i] - b.position).normalized(), 250.0)
	game.horde.death_override = previous
	game.horde._physics_process(1.0 / 60.0)
	for k in 5:
		b._physics_process(0.23)
		await game.get_tree().create_timer(0.12).timeout
	await save(game, prefix + "death.png")
	var state := CampaignRules.initial(812)
	state["turn"] = 7
	state["war"]["assault_unlocked"] = true
	state["war"]["outposts"] = ["north_america", "west_europe", "siberia"]
	state["war"]["samples"] = ["east_asia", "south_asia"]
	state["war"]["front"] = {}
	state["nests"]["object_7"]["alive"] = false
	state["nests"]["hive_heart"]["discovered"] = true
	state["offers"] = CampaignDirector.generate(state)
	Meta.campaign = state
	var layer := CanvasLayer.new()
	layer.layer = 100
	game.get_tree().root.add_child(layer)
	game.get_node("HUD").visible = false
	game.get_node("Overlay").visible = false
	var base := load("res://scenes/base.tscn").instantiate() as Control
	game.get_tree().set_meta("s6_return_to_base", true)
	layer.add_child(base)
	base._tab = base.Tab.OPERATIONS
	base._open_operations()
	base._select_region("south_asia")
	base._globe.skip_motion()
	base.queue_redraw()
	await game.get_tree().create_timer(0.4).timeout
	await save(game, prefix + "globe.png")
	base.free()
	var ended: Dictionary = CampaignRules.advance(state, state["offers"][2], "victory")["world"]
	var ending := WarEnding.new()
	ending.world = ended
	layer.add_child(ending)
	await game.get_tree().create_timer(3.2).timeout
	await save(game, prefix + "victory.png")
	ending.free()
	layer.free()
	b.free()
	game.boss = original


static func _general(game: Node, original: Boss, prefix: String) -> void:
	var b := BossGeneral.new()
	game.get_node("World").add_child(b)
	b.set_physics_process(false)
	b.player = game.player
	b.horde = game.horde
	b.obstacles = game.obstacles
	b.effects = game.effects
	b.floor_decals = game.floor_decals
	b.arena = game.ARENA
	game.boss = b
	var center: Vector2 = game.obstacles.free_point(game.ARENA.get_center(), 40.0)
	b.start(center)
	game.player.position = game.obstacles.free_point(center + Vector2(170, 60), Player.RADIUS)
	game.camera.position = center + Vector2(40, 0)
	game.camera.zoom = Vector2.ONE * 2.5
	game.camera.reset_smoothing()
	game.horde._physics_process(1.0 / 60.0)
	for phase in [1, 2, 3]:
		b.phase = phase
		b.hp = b.max_hp * [1.0, 0.6, 0.25][phase - 1]
		b._flash = 0.0
		if phase == 1:
			b._begin_barrage()
			for i in b._timers.size():
				b._timers[i] += 0.9
		elif phase == 2:
			b._damage_plate(3, BossGeneral.PLATES[3], Vector2.LEFT)
			b._damage_plate(0, BossGeneral.PLATES[0], Vector2.LEFT)
			b._begin_shield_charge()
			b._age = 0.7
		else:
			b._damage_plate(1, BossGeneral.PLATES[1], Vector2.LEFT)
			b._damage_plate(2, BossGeneral.PLATES[2], Vector2.LEFT)
			b._state = Boss.State.WALK
			b._targets.clear()
			b._timers.clear()
			b._struck.clear()
			b._order_age = 0.65
			b._summon_squad()
			game.horde._physics_process(1.0 / 60.0)
		b.queue_redraw()
		game.get_node("HUD/Hud").queue_redraw()
		await save(game, prefix + "general_%d.png" % phase)
	b.free()
	game.boss = original
