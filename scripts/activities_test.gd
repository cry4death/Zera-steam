class_name ActivitiesTest
extends RefCounted
## Переходы активностей, достижимость трёх карт и оконные кадры.

static var checks := 0
static var failures := 0


static func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("ACTIVITIESTEST %s=%s" % [label, ok])


static func run(game: Node) -> void:
	game.set_physics_process(false)
	game.set_process(false)
	game.spawner.enabled = false
	game.weapons.set_physics_process(false)
	game.player.set_physics_process(false)
	game.player.god_mode = true
	game.horde.set_physics_process(false)
	game.pickups.set_physics_process(false)
	game.gems.set_physics_process(false)
	game.credit_drops.set_physics_process(false)
	var a: Activities = game.activities
	a.set_physics_process(false)
	game.time = 100.0
	var original: Obstacles = game.obstacles
	var original_arena: Rect2 = game.ARENA
	var original_position: Vector2 = game.player.position
	for map_id: String in MapLoader.IDS:
		var data := MapLoader.load_map(map_id)
		var rect := Rect2(Vector2.ZERO, data["size"])
		game.ARENA = rect
		game.player.position = data["start"]
		for run_seed: int in [81073, 27, 96241]:
			var obs := Obstacles.new()
			game.get_node("World").add_child(obs)
			obs.setup(rect, MapLoader.layout(data, run_seed))
			while obs.nav_completed == 0:
				obs.navigation_step(0.0, game.player.position)
			game.obstacles = obs
			a._rng.seed = run_seed
			var all_reachable := true
			for kind in Activities.Kind.size():
				a.kind = kind as Activities.Kind
				for attempt in 4:
					var at := a.find_site()
					var path := a.path_between(game.player.position, at)
					var escape := a.make_route(at)
					all_reachable = all_reachable and a.valid_site(at) and not path.is_empty() and escape.size() >= 5
					if kind == Activities.Kind.ARTILLERY:
						var axis := a.strike_axis(at)
						var center := at - axis.orthogonal() * 80.0
						for j in 6:
							var blast := center + axis * (float(j) * 40.0 - 100.0)
							all_reachable = all_reachable and not obs.contains(blast, Activities.STRIKE_RADIUS)
					for p: Vector2 in escape:
						all_reachable = all_reachable and not obs.contains(p, 14.0)
			check(all_reachable, "reachable_%s_%d_six_kinds" % [map_id, run_seed])
			var plan := Activities.make_schedule(run_seed, map_id)
			check(plan == Activities.make_schedule(run_seed, map_id), "seed_%s_%d" % [map_id, run_seed])
			check(plan != Activities.make_schedule(run_seed + 1, map_id), "variety_%s_%d" % [map_id, run_seed])
			var types := PackedInt32Array()
			for row: Dictionary in plan:
				types.append(int(row["kind"]))
			var unique := true
			for k in types.size():
				unique = unique and types.count(types[k]) == 1
			check(plan.size() >= 4 and plan.size() <= 5 and unique and float(plan[2]["time"]) >= 210.0 and float(plan[2]["time"]) <= 220.0, "pool_%s_%d" % [map_id, run_seed])
			obs.free()
	game.obstacles = original
	game.ARENA = original_arena
	game.player.position = original_position
	a.kind = Activities.Kind.ARTILLERY
	var site := a.find_site()
	for kind in Activities.Kind.size():
		a.phase = Activities.Phase.IDLE
		game.time = 100.0
		game.player.position = original_position
		check(a.begin(kind, site), "%s_start" % Activities.NAMES[kind])
		var before := a.rewards
		var modules_before: int = game.pickups.count_of(Pickups.Kind.ACTIVITY_MODULE)
		var xp_before: int = game.gems.spawned_total
		var credits_before: int = game.credit_drops.spawned_total
		check(not a.begin((kind + 1) % Activities.Kind.size(), site), "%s_no_overlap" % Activities.NAMES[kind])
		match kind:
			Activities.Kind.SUPPLY:
				game.player.position = site
				a.advance(9.0)
				game.player.position = site + Vector2(120, 0)
				a.advance(2.0)
				check(is_equal_approx(a._work, 9.0), "supply_pause_keeps_work")
				game.player.position = site
				a.advance(9.0)
			Activities.Kind.CARRIER:
				var i := a.carrier_index()
				game.player.position = site + Vector2(-120, 0)
				var at: Vector2 = game.horde.pos[i]
				a.advance(0.1)
				check(game.horde.pos[i].distance_to(at) > 1.0, "carrier_moves_on_route")
				game.horde.freeze_t[i] = 2.0
				at = game.horde.pos[i]
				a.advance(0.1)
				check(game.horde.pos[i] == at, "carrier_freeze_works")
				game.horde.damage(i, 9999.0, Vector2.RIGHT, 0.0)
				game.horde._compact()
				a.advance(0.1)
			Activities.Kind.FUEL:
				game.player.position = site + Vector2(28, 16)
				a.advance(2.0)
				check(a._fuse == Activities.FUSE, "fuel_armed_by_contact")
				game.player.position = site + Vector2(110, 0)
				game.horde.spawn(site + Vector2(20, 0))
				game.horde._rebuild_grid()
				var kills_before: int = game.kills
				a.advance(6.0)
				check(game.kills > kills_before, "fuel_actual_horde_damage")
			Activities.Kind.APC:
				game.player.position = site
				a.advance(6.0)
				check(a._work == 0.0, "apc_requires_side_panel")
				game.player.position = site + Vector2(25, 40)
				a.advance(6.0)
				game.player.position = site + Vector2(-100, 0)
				a.advance(2.0)
				check(a._work == 6.0, "apc_retreat_keeps_work")
				game.player.position = site + Vector2(25, 40)
				a.advance(6.0)
			Activities.Kind.TURRET:
				game.player.position = site + Vector2(-18, 16)
				a.advance(4.0)
				check(a._support == 20.0, "generator_powers_twenty_seconds")
				var shots_before := a.support_shots
				var hits_before := a.support_hits
				game.horde.count = 0
				game.horde.spawn(site + Vector2(100, -5))
				game.horde._rebuild_grid()
				for tick in 402:
					a.advance(0.05)
				check(a.support_shots > shots_before and a.support_hits > hits_before and game.horde.dead[0] == 1, "turret_real_bullets_kill")
			Activities.Kind.ARTILLERY:
				game.player.position = site
				a.advance(2.0)
				check(a._marked and a._fuse == 6.0, "artillery_contact_marks_strip")
				game.player.position = site + a._strike_axis.orthogonal() * 90.0
				game.horde.count = 0
				game.horde.spawn(a.strike_center())
				game.horde._rebuild_grid()
				var blasts_before := a.artillery_blasts
				for tick in 160:
					a.advance(0.05)
				check(a.artillery_blasts == blasts_before + 6 and game.horde.dead[0] == 1, "artillery_six_real_explosive_hits")
		check(a.phase == Activities.Phase.RESOLVED and a.rewards == before + 1, "%s_success_reward" % Activities.NAMES[kind])
		if kind in [Activities.Kind.SUPPLY, Activities.Kind.APC]:
			check(game.pickups.count_of(Pickups.Kind.ACTIVITY_MODULE) == modules_before + 1, "supply_one_physical_reward")
		elif kind == Activities.Kind.CARRIER:
			check(game.gems.spawned_total == xp_before + 36 and game.pickups.count_of(Pickups.Kind.MEDKIT) >= 1, "carrier_real_medkit_xp")
		elif kind == Activities.Kind.FUEL:
			check(game.credit_drops.spawned_total >= credits_before + 18, "fuel_real_credit_drop")
		else:
			check(game.pickups.count_of(Pickups.Kind.ACTIVITY_MODULE) == modules_before, "%s_support_without_extra_module" % Activities.NAMES[kind])
		a.finish(true)
		a.advance(100.0)
		check(a.rewards == before + 1, "%s_reward_once" % Activities.NAMES[kind])
		a.phase = Activities.Phase.IDLE
		check(a.begin(kind, site), "%s_restart" % Activities.NAMES[kind])
		before = a.rewards
		var failed_before := a.failed
		if kind == Activities.Kind.FUEL:
			game.player.position = site + Vector2(28, 16)
			a.advance(2.0)
			game.player._iframes = 0.0
			var damage_before: float = game.player.damage_taken
			a.advance(6.0)
			check(game.player.damage_taken >= damage_before + 40.0, "fuel_staying_is_dangerous")
		else:
			game.player.position = site + Vector2(-300, 0)
			a.advance(71.0)
		check(a.failed == failed_before + 1 and a.rewards == before, "%s_failure_no_reward" % Activities.NAMES[kind])
		var carrier := a.carrier_index()
		check(carrier < 0 and a._route.is_empty(), "%s_released_state" % Activities.NAMES[kind])
	# Завершение забега посреди эпизода снимает управление носителем без награды.
	a.phase = Activities.Phase.IDLE
	a.begin(Activities.Kind.CARRIER, site)
	var actor := a.carrier_index()
	var saved_speed := a._carrier_speed
	var reward_before := a.rewards
	game.game_over = true
	a.enabled = true
	a._physics_process(0.1)
	check(not a.is_active() and a.target == Vector2.INF and a._route.is_empty() and a._bot_path.is_empty() and not a.is_physics_processing() and a.rewards == reward_before and game.pickups.count_of(Pickups.Kind.ACTIVITY_MODULE) == 0, "end_clears_activity_without_reward")
	check(actor >= 0 and game.horde.speed[actor] == saved_speed, "end_releases_carrier")
	game.game_over = false
	game.time = 100.0
	a.enabled = true
	a.offered = 0
	a._next = 0
	a._cool_until = 0.0
	a._defer_until = -1.0
	a.schedule.assign([{"time": 100.0, "kind": Activities.Kind.SUPPLY}])
	game.player.hp = 20.0
	a._physics_process(0.1)
	check(not a.is_active() and a._next == 0, "director_defers_when_hurt")
	game.time = 116.0
	a._physics_process(0.1)
	check(a.is_active() and a.offered == 1, "director_keeps_first_two_optional_offers")
	a.finish(false)
	a.phase = Activities.Phase.IDLE
	a.offered = 2
	a._next = 0
	a._cool_until = 0.0
	a._defer_until = -1.0
	game.time = 100.0
	a._physics_process(0.1)
	game.time = 116.0
	a._physics_process(0.1)
	check(a.is_active() and a._next == 1, "director_keeps_later_offer_optional")
	a.finish(false)
	a._next = 0
	game.time = 600.0
	a._physics_process(0.1)
	check(not a.is_active() and a._next == 1, "director_no_overdue_debt")
	game.time = 100.0
	game.player.hp = 100.0
	a.phase = Activities.Phase.IDLE
	a.begin(Activities.Kind.SUPPLY, site)
	var before_protected := a.rewards
	game.time = 285.0
	a.advance(20.0)
	check(not a.is_active() and a.rewards == before_protected, "trader_priority_no_reward")
	game.spawner.enabled = true
	game.spawner.time = 100.0
	while game.horde.count < 100:
		game.horde.spawn(site + Vector2(150, 0))
	var count_before: int = game.horde.count
	check(game.spawner.activity_wave(10) == 0 and game.horde.count == count_before, "wave_respects_existing_cap")
	game.spawner.alarm = true
	check(game.spawner.activity_wave(10) == 0, "alarm_blocks_activity_wave")
	game.spawner.enabled = false
	for type: String in ["clearance", "reclaim", "extract", "nest"]:
		var plan := Activities.operation_schedule(81073, type)
		check(plan == Activities.operation_schedule(81073, type) and plan.size() == (1 if type in ["clearance", "reclaim"] else 0), "campaign_one_optional_" + type)
	game.spawner.alarm = false
	game.time = 100.0
	a.phase = Activities.Phase.IDLE
	a.begin(Activities.Kind.ARTILLERY, site)
	game.player.position = site
	a.advance(2.0)
	game.player.position = a.strike_center() - a._strike_axis * 100.0
	game.player._iframes = 0.0
	var unsafe_reward := a.rewards
	var unsafe_damage: float = game.player.damage_taken
	for tick in 160:
		a.advance(0.05)
	check(a.phase == Activities.Phase.RESOLVED and not a._strike_safe and a.rewards == unsafe_reward and game.player.damage_taken >= unsafe_damage + 40.0, "artillery_staying_in_strip_fails")
	var original_objective: CampaignObjective = game.objective
	var operation_goal := CampaignObjective.new()
	game.objective = operation_goal
	operation_goal.spawned = true
	a.phase = Activities.Phase.IDLE
	a.begin(Activities.Kind.APC, site)
	a.advance(0.1)
	check(not a.is_active() and a.rewards == unsafe_reward, "campaign_objective_cancels_optional_episode")
	game.objective = original_objective
	operation_goal.free()
	var director := HordeDirector.new()
	director.setup(game.horde, game.player, 81073, game._map_id)
	check(not director.activity_window(115.0) and director.activity_window(130.0), "director_peak_delays_offer")
	director.activity_finished(200.0)
	check(is_equal_approx(director.advance(201.0, 0.1, [100, 0, 0, 0], false), 0.85) and director.phase == HordeDirector.Phase.RELAX, "director_activity_recovery")
	a.clear()
	print("ACTIVITIESTEST checks=%d failures=%d rewards=%d ok=%s" % [checks, failures, a.rewards, failures == 0])
	Meta.finish_test(0 if failures == 0 else 1)


static func capture(game: Node, path: String) -> void:
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png(path)
	print("ACTIVITYSHOT ", path)


static func shots(game: Node, shot_path: String) -> void:
	seed(81073)
	game.set_physics_process(false)
	game.set_process(false)
	game.spawner.enabled = false
	game.player.god_mode = true
	game.player.set_physics_process(false)
	game._sim = true
	game.gems.collected.disconnect(game.progression.add_xp)
	game.camera.shake_multiplier = 0.0
	game.camera.position_smoothing_enabled = false
	var a: Activities = game.activities
	a.enabled = true
	a.set_physics_process(false)
	game.time = 210.0 if game.mission_config.is_empty() else 135.0
	game.horde.minutes = game.time / 60.0
	var dir := "res://design/tasks/reports" if shot_path.is_empty() else shot_path.get_base_dir()
	var prefix := "ev2" if game.mission_config.is_empty() else "ev2_campaign"
	a.kind = Activities.Kind.ARTILLERY
	var site := a.find_site()
	var kinds: Array[int] = [Activities.Kind.APC, Activities.Kind.TURRET, Activities.Kind.ARTILLERY]
	if not game.mission_config.is_empty():
		kinds.assign([a.schedule[0]["kind"]])
	for kind: int in kinds:
		a.phase = Activities.Phase.IDLE
		game.horde.count = 0
		game.horde._rebuild_grid()
		game.player.position = site + Vector2(-70, 45)
		game.camera.position = site + Vector2(-25, 0)
		check(a.begin(kind, site), "shot_%s_started" % Activities.NAMES[kind])
		game.weapons.set_physics_process(kind == Activities.Kind.APC)
		game.announce_t = 0.0
		game.radio_t = 0.0
		for j in 150:
			game.horde.spawn(site + Vector2.from_angle(randf() * TAU) * randf_range(110, 240), j % 3)
		await game.get_tree().create_timer(0.15).timeout
		await capture(game, dir.path_join("%s_%s_start.png" % [prefix, Activities.NAMES[kind]]))
		game.player.position = site + (Vector2(25, 40) if kind == Activities.Kind.APC else (Vector2(-18, 16) if kind == Activities.Kind.TURRET else Vector2.ZERO))
		var ticks := 80 if kind != Activities.Kind.ARTILLERY else 20
		for tick in ticks:
			a.advance(0.1)
			await game.get_tree().create_timer(0.1).timeout
		if kind == Activities.Kind.ARTILLERY:
			game.player.position = site + a._strike_axis.orthogonal() * 70.0
			for tick in 57:
				a.advance(0.1)
				await game.get_tree().create_timer(0.1).timeout
			for j in 36:
				game.horde.spawn(a.strike_center() + a._strike_axis * randf_range(-110, 110) + a._strike_axis.orthogonal() * randf_range(-28, 28), j % 3)
			for tick in 10:
				a.advance(0.1)
				await game.get_tree().create_timer(0.1).timeout
		if kind == Activities.Kind.TURRET:
			a.advance(0.1)
		await capture(game, dir.path_join("%s_%s_peak.png" % [prefix, Activities.NAMES[kind]]))
		if kind == Activities.Kind.APC and game.mission_config.is_empty():
			game.player.position = game.obstacles.free_point(site + Vector2(110, 40), Player.RADIUS)
			a.advance(0.35)
			await game.get_tree().create_timer(0.35).timeout
			await capture(game, dir.path_join("ev2_apc_retreat.png"))
		if not game.mission_config.is_empty():
			await capture(game, dir.path_join("ev2_campaign.png"))
		a.finish(false)
		await game.get_tree().create_timer(0.3).timeout
	if game.mission_config.is_empty():
		a.phase = Activities.Phase.IDLE
		a.begin(Activities.Kind.APC, site)
		game.player.position = game.obstacles.free_point(site + Vector2(-480, 0), Player.RADIUS)
		await game.get_tree().create_timer(0.35).timeout
		await capture(game, dir.path_join("ev2_pointer.png"))
		a.finish(false)
	print("ACTIVITYSHOTS ok=true standard_camera=true staged=true shots=%d hits=%d blasts=%d" % [a.support_shots, a.support_hits, a.artillery_blasts])
	Meta.finish_test()
