extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	seed(404)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.set_physics_process(false)
	game.spawner.enabled = false
	game.player.set_physics_process(false)
	game.player.god_mode = true
	game.boss.set_physics_process(false)
	game.weapons.set_physics_process(false)
	game.gems.collected.disconnect(game.progression.add_xp)
	var w: Weapons = game.weapons
	var boss: Boss = game.boss
	var at: Vector2 = game.player.global_position + Vector2(100, 0)
	for base in 8:
		w.slots.clear()
		w.add_weapon(base)
		w.slots[0].level = 5
		w.slots[0].ammo_rank = 3
		w.refresh(0)
		w.slots[0].mag = w.slots[0].stats["mag"]
		w.bullet_count = 0
		boss.start(at)
		var before := boss.hp
		for step in 240:
			w._physics_process(1.0 / 60.0)
		assert(boss.hp < before)
		print("S4CHECK gun=%s damage=%.2f shots=%d" % [Weapons.GUN_IDS[base], before - boss.hp, w.shots[base]])
		# Выпущенные гранаты не переходят к следующему стволу.
		w.firing_enabled = false
		for step in 180:
			w._physics_process(1.0 / 60.0)
		w.firing_enabled = true
	w.slots.clear()
	w.add_weapon(WeaponDefs.Base.RIFLE)
	w.slots[0].ammo = WeaponDefs.Ammo.INCENDIARY
	w.slots[0].ammo_rank = 3
	w.slots[0].modules = [{"id": WeaponDefs.Module.CHAIN, "rank": 3, "rare": false}]
	w.refresh(0)
	w.firing_enabled = false
	boss.start(at)
	w._boss_active = true
	w._hit_boss(0, 10, Vector2.RIGHT, at, "bullet")
	for step in 120:
		w._physics_process(1.0 / 60.0)
	assert(float(w.boss_sources.get("fire", 0)) > 0)
	w.explode(at, 100, 50)
	assert(float(w.boss_sources.get("grenade", 0)) > 0)
	w._spawn_bullet(at - Vector2(30, 0), Vector2(450, 0), 1, 30, 0, 2, 0, 0)
	var before := boss.hp
	for step in 30:
		w._update_bullets(1.0 / 60.0)
	assert(is_equal_approx(before - boss.hp, 22.5))
	print("S4CHECK pierce boss_hit_once=true")
	var enemy: int = game.horde.spawn(at - Vector2(35, 0))
	game.horde._physics_process(0.0)
	w._on_kill(0, enemy, Vector2.RIGHT, 0)
	for step in 30:
		w._update_bullets(1.0 / 60.0)
	assert(float(w.boss_sources.get("chain", 0)) > 0)
	w.slots[0].ammo = WeaponDefs.Ammo.EXPANSIVE
	w._hit_enemy(0, enemy, 1, Vector2.RIGHT, game.horde.pos[enemy], 0)
	# Радиус экспансивных III равен 20, радиус босса добавляется при hit_test.
	assert(float(w.boss_sources.get("expansive", 0)) > 0)
	w.slots[0].modules.append({"id": WeaponDefs.Module.SPLIT, "rank": 3, "rare": false})
	w._spawn_shards(0, at - Vector2(25, 0), Vector2.RIGHT, 20, -1)
	for step in 30:
		w._update_bullets(1.0 / 60.0)
	assert(float(w.boss_sources.get("shard", 0)) > 0)
	print("S4CHECK shards=true chain=true fire=true grenade=true expansive=true")
	print("S4CHECK sources=", w.boss_sources)
	game.time = 630
	game.kills = 150
	game.elites_killed = 3
	assert(game._result_stats(false)["dna_total"] == 123)
	assert(game._result_stats(true)["dna_total"] == 184)
	game.player.god_mode = false
	game.player.take_damage(9999)
	await create_timer(0.7).timeout
	assert(game.results.visible and paused and not game.results._stats["victory"])
	print("S4CHECK defeat results=true paused=true dna=123")
	# Один клик допечатывает, второй перезапускает всю сцену и снимает паузу.
	game.results._t = 0.3
	game.results._activate()
	assert(game.results._finished and game.results.visible)
	game.results._activate()
	await process_frame
	await process_frame
	assert(current_scene != game and not paused)
	assert(current_scene.time < 1.0 and current_scene.military_crates == 0 and not current_scene.results.visible)
	print("S4CHECK restart reset=true paused=false")
	quit()
