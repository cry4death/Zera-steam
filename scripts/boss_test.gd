class_name BossTest
extends RefCounted
## Проверки настоящих атак по обе стороны границы телеграфа.

static var checks := 0
static var failed := 0


static func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		failed += 1
		print("BOSSTEST FAIL ", label)


static func make_boss(game: Node, kind: int) -> BossHive:
	var b := BossHive.new()
	b.hive = kind
	game.get_node("World").add_child(b)
	b.set_physics_process(false)
	b.player = game.player
	b.horde = game.horde
	b.arena = game.ARENA
	b.start(game.ARENA.get_center())
	return b


static func tick(b: Boss, seconds: float) -> void:
	for k in ceili(seconds * 60.0):
		b._physics_process(1.0 / 60.0)


static func run(game: Node) -> bool:
	game.process_mode = Node.PROCESS_MODE_DISABLED
	checks = 0
	failed = 0
	game.player.god_mode = true
	game.player._iframes = 0.0
	var center: Vector2 = game.ARENA.get_center()
	for kind in [BossHive.Hive.MOTHER, BossHive.Hive.MEAT]:
		var b := make_boss(game, kind)
		check("start_alive", b.is_alive() and b.phase == 1 and b.hp == BossHive.HIVE_HP[kind])
		check("body_hit", b.hit_test(center, 0.0) and not b.hit_test(center + Vector2(300, 0), 1.0))
		b.take_damage(b.max_hp * 0.36, Vector2.RIGHT, center)
		check("phase2", b.phase == 2)
		b.take_damage(b.max_hp * 0.36, Vector2.RIGHT, center)
		check("phase3", b.phase == 3)
		if kind == BossHive.Hive.MEAT:
			b._tick_marks(0.86)
			check("shed_actual_horde_count", b.pieces >= 12 and game.horde.count >= b.pieces)
			check("core_smaller", b.body_radius() == 16.0)
		var deaths := [0]
		b.died.connect(func(_at: Vector2) -> void: deaths[0] += 1)
		b.take_damage(99999.0, Vector2.RIGHT, center)
		b.take_damage(99999.0, Vector2.RIGHT, center)
		check("death_once_no_pending_attacks", deaths[0] == 1 and not b.is_alive() and b._marks.is_empty())
		b.free()
	var mother := make_boss(game, BossHive.Hive.MOTHER)
	for attack in [BossHive.Attack.TENTACLE, BossHive.Attack.BIOMASS]:
		for dodge in [false, true]:
			mother.start(center)
			mother._attack_cd = 999.0
			mother._birth_cd = 999.0
			game.player.global_position = center + Vector2(160, 0)
			var damage_before: float = game.player.damage_taken
			mother._begin_mark(game.player.global_position, attack)
			var target := mother._marks[0]
			tick(mother, BossHive.MARK_WARNING[attack] - 0.05)
			check("no_damage_before_warning", game.player.damage_taken == damage_before)
			if dodge:
				game.player.global_position += Vector2(0, 100)
			tick(mother, 0.1)
			check("locked_telegraph", mother._marks[0] == target)
			check("dodge_or_hit", is_equal_approx(game.player.damage_taken - damage_before, 0.0 if dodge else 25.0))
			tick(mother, 0.3)
			check("one_hit_per_mark", is_equal_approx(game.player.damage_taken - damage_before, 0.0 if dodge else 25.0))
	mother.start(center)
	mother._attack_cd = 999.0
	game.player.position = center + Vector2(170, 0)
	var before_count: int = game.horde.count
	mother._birth_age = 0.0
	tick(mother, 1.6)
	check("birth_counted", game.horde.count - before_count == 8 and mother.births == 1)
	var birth_delay := mother._birth_cd
	for k in 4:
		mother.take_damage(BossHive.SAC_HP, Vector2.RIGHT, center + BossHive.SAC_OFFSETS[k])
	check("sacs_shootable", mother._sacs == PackedFloat32Array([0, 0, 0, 0]))
	check("no_sac_hit_after_destroy", not mother.hit_test(center + Vector2(-45, -31), 0.0))
	mother._birth_age = 0.0
	before_count = game.horde.count
	tick(mother, 1.6)
	check("sacs_reduce_brood_speed_up", game.horde.count - before_count == 2 and mother._birth_cd < birth_delay)
	check("mother_stationary", mother.global_position == center)
	mother.free()
	for dodge in [false, true]:
		var meat := make_boss(game, BossHive.Hive.MEAT)
		game.player.global_position = center + Vector2(160, 0)
		var before_damage: float = game.player.damage_taken
		meat._begin_roll()
		tick(meat, 1.1)
		check("roll_waits", meat.global_position == center and game.player.damage_taken == before_damage)
		var target := meat._roll_to
		if dodge:
			game.player.global_position += Vector2(0, 140)
		tick(meat, 1.4)
		check("roll_fixed_target", meat._roll_to == target)
		check("roll_hit_or_dodge", is_equal_approx(game.player.damage_taken - before_damage, 0.0 if dodge else 35.0))
		check("roll_leaves_rot", meat._marks.size() > 0)
		meat.free()
	var rot := make_boss(game, BossHive.Hive.MEAT)
	rot.phase = 3
	game.player.global_position = rot.global_position
	var contact_before: float = game.player.damage_taken
	rot._contact()
	rot._contact()
	check("core_contact_escape_window", rot._contact_cd == 1.2 and game.player.damage_taken == contact_before + 25.0)
	rot._attack_cd = 999.0
	game.player.global_position = center + Vector2(180, 0)
	var speed: float = game.player.move_speed
	rot._begin_mark(game.player.global_position, BossHive.Attack.ROT)
	rot._tick_marks(0.9)
	check("rot_warn_no_slow", is_equal_approx(game.player.move_speed, speed))
	rot._tick_marks(0.2)
	check("rot_slow", is_equal_approx(game.player.move_speed, speed * 0.60))
	rot._restore_speed()
	game.player.global_position += Vector2(100, 0)
	rot._tick_marks(0.1)
	check("rot_escape_restores_speed", is_equal_approx(game.player.move_speed, speed))
	rot._begin_mark(game.player.global_position, BossHive.Attack.ROT)
	rot._tick_marks(1.1)
	rot.take_damage(99999, Vector2.RIGHT, center)
	check("death_restores_speed", is_equal_approx(game.player.move_speed, speed))
	rot.free()
	# Общий лимит нельзя обойти рождением/отрывом.
	var cap := make_boss(game, BossHive.Hive.MOTHER)
	var saved_count: int = game.horde.count
	game.horde.count = Horde.MAX_ENEMIES
	cap._spawn_enemy(center, Horde.Kind.RUNNER)
	check("shared_horde_cap", game.horde.count == Horde.MAX_ENEMIES)
	game.horde.count = saved_count
	cap.free()
	_object7(game, center)
	_heart(game, center)
	_general(game, center)
	_campaign()
	_final_scene(game)
	print("BOSSTEST checks=%d failed=%d" % [checks, failed])
	return failed == 0


static func _final_scene(game: Node) -> void:
	var original: Boss = game.boss
	var old_mission: Dictionary = game.mission_config
	var b := BossHeart.new()
	game.get_node("World").add_child(b)
	b.set_physics_process(false)
	game.boss = b
	var state := CampaignRules.initial(812)
	state["turn"] = 7
	state["war"]["assault_unlocked"] = true
	state["war"]["front"] = {}
	state["nests"]["object_7"]["alive"] = false
	state["nests"]["hive_heart"]["discovered"] = true
	state["offers"] = CampaignDirector.generate(state)
	Meta.reset()
	Meta.campaign = state
	game.mission_config = Campaign.start_operation(state["offers"][2]["id"])
	check("heart_final_scene_pending", not game.mission_config.is_empty())
	game._open_results(true)
	var ending: WarEnding
	for child: Node in game.get_node("Overlay").get_children():
		if child is WarEnding:
			ending = child
	check("heart_real_results_commit_then_ending", ending != null and Meta.campaign["phase"] == "victory" and Meta.runs == 1 and not game.results.visible)
	if ending:
		check("heart_ending_uses_committed_world", ending.world["turn"] == 8 and not ending.world["nests"]["hive_heart"]["alive"])
		ending.base_requested.disconnect(game._return_to_base)
		var pressed := [false]
		ending.base_requested.connect(func() -> void: pressed[0] = true)
		ending._process(3.1)
		ending._button.pressed.emit()
		check("heart_ending_returns_to_base", pressed[0] and ending._button.visible)
		ending.free()
	game.get_tree().paused = false
	game.game_over = false
	game.mission_config = old_mission
	game.boss = original
	b.free()
	Meta.reset()


static func _heart(game: Node, center: Vector2) -> void:
	var b := BossHeart.new()
	game.get_node("World").add_child(b)
	b.set_physics_process(false)
	b.player = game.player
	b.horde = game.horde
	b.arena = game.ARENA
	b.start(center)
	check("heart_central_huge", b.global_position == center and b.body_radius() > 3.0 * Boss.RADIUS and b.hp == BossHeart.HEART_HP)
	check("heart_organic_corners_not_rectangular", b.inside_tissue(center + Vector2(160, 80), Player.RADIUS) and not b.inside_tissue(center + Vector2(320, 190)) and b.cage().has_point(center + Vector2(320, 190)))
	b.take_damage(1000.0, Vector2.RIGHT, center + Vector2(55, 0))
	check("heart_shell_protects", is_equal_approx(b.hp, b.max_hp - 720.0))
	for next_phase in [2, 3, 4]:
		b._begin_attack(center + Vector2(150, 0), BossHeart.Attack.ACID)
		b.hp = b.max_hp * [0.75, 0.40, 0.12][next_phase - 2]
		b.take_damage(1.0, Vector2.RIGHT, center)
		check("heart_phase_%d" % next_phase, b.phase == next_phase and b._from.is_empty())
	b.start(center)
	b.phase = 2
	b.hp = b.max_hp * 0.65
	var healthy := b.hp
	b.take_damage(100.0, Vector2.RIGHT, center + Vector2(55, 0))
	check("heart_open_surface_damage", is_equal_approx(healthy - b.hp, 100.0))
	healthy = b.hp
	b.take_damage(100.0, Vector2.RIGHT, center)
	check("heart_exposed_chambers_damage", is_equal_approx(healthy - b.hp, 100.0 * BossHeart.CORE_DAMAGE))
	for kind in [BossHeart.Attack.WAVE, BossHeart.Attack.WHIP, BossHeart.Attack.ACID]:
		for dodge in [false, true]:
			b.start(center)
			b._attack_cd = 999.0
			b._brood_cd = 999.0
			game.player.position = center + Vector2(160, 0)
			game.player._iframes = 0.0
			var before: float = game.player.damage_taken
			b._begin_attack(game.player.position, kind)
			var target := b._to[0]
			tick(b, BossHeart.WARNING[kind] - 0.05)
			check("heart_no_hit_before_%d" % kind, game.player.damage_taken == before)
			if dodge:
				game.player.position += Vector2(90, 90)
			tick(b, 1.2)
			check("heart_locked_target_%d" % kind, b._to.is_empty() or b._to[0] == target)
			check("heart_hit_or_dodge_%d" % kind, is_equal_approx(game.player.damage_taken - before, 0.0 if dodge else 25.0))
			tick(b, 0.4)
			check("heart_single_hit_%d" % kind, is_equal_approx(game.player.damage_taken - before, 0.0 if dodge else 25.0))
	b.start(center)
	b._attack_cd = 999.0
	b._brood_cd = 999.0
	b.phase = 4
	game.player.position = center + Vector2(200, 0)
	var before: float = game.player.damage_taken
	tick(b, 0.5)
	check("heart_walls_telegraph_slowly", b._cage_half.x > BossHeart.HALF[3].x and b._cage_half.x < BossHeart.HALF[0].x and game.player.damage_taken == before)
	game.player.position = center + Vector2(370, 0)
	tick(b, 1.3)
	check("heart_walls_bite", game.player.damage_taken > before)
	game.player.position = center + Vector2(150, 0)
	b.start(center)
	var count_before: int = game.horde.count
	b._summon()
	var seen := PackedByteArray([0, 0, 0, 0])
	for i in range(count_before, game.horde.count):
		seen[game.horde.kind[i]] = 1
	check("heart_summons_all_types", seen == PackedByteArray([1, 1, 1, 1]) and b.spawned == 8)
	var saved_count: int = game.horde.count
	game.horde.count = Horde.MAX_ENEMIES
	b._summon()
	check("heart_shared_horde_cap", game.horde.count == Horde.MAX_ENEMIES)
	game.horde.count = saved_count
	var deaths := [0]
	b.died.connect(func(_at: Vector2) -> void: deaths[0] += 1)
	b._begin_attack(game.player.position, BossHeart.Attack.WHIP)
	b.take_damage(999999, Vector2.RIGHT, center)
	b.take_damage(999999, Vector2.RIGHT, center)
	before = game.player.damage_taken
	tick(b, 2.0)
	check("heart_death_once_cancels_everything", deaths[0] == 1 and b._from.is_empty() and game.player.damage_taken == before and b._death_step == 5 and b.visible)
	b.free()


static func _general(game: Node, center: Vector2) -> void:
	var b := BossGeneral.new()
	game.get_node("World").add_child(b)
	b.set_physics_process(false)
	b.player = game.player
	b.horde = game.horde
	b.arena = game.ARENA
	b.start(center)
	check("general_start_squad_z2", b.summoned == 5 and b.armor_mask == 15 and b.hp == BossGeneral.GENERAL_HP)
	var before := b.hp
	b.take_armored_damage(100, Vector2.LEFT, center + Vector2(26, 0), 0.0, false)
	check("general_shield_absorbs", b.hp == before and b.armor[3] == BossGeneral.PLATES[3] - 100)
	b.take_armored_damage(100, Vector2.LEFT, center + Vector2(26, 0), 1.0, false)
	check("general_ap_reaches_body", b.hp == before - 100 and b.armor[3] < BossGeneral.PLATES[3] - 100)
	var detached := [0]
	var collect := func(_p: Vector2, _d: Vector2, _f: float, code: int, part: int) -> void:
		if code == BossGeneral.MILITARY_CODE and part == 3: detached[0] += 1
	game.horde.armor_detached.connect(collect)
	b._damage_plate(3, 9999, Vector2.LEFT)
	b._damage_plate(3, 9999, Vector2.LEFT)
	check("general_plate_z2_detaches_once", detached[0] == 1 and not (b.armor_mask & 8))
	game.horde.armor_detached.disconnect(collect)
	before = b.hp
	b.take_armored_damage(100, Vector2.LEFT, center + Vector2(26, 0), 0.0, false)
	check("general_exposed_helmet_still_protects", b.hp == before and b.armor[0] < BossGeneral.PLATES[0])
	for dodge in [false, true]:
		b.start(center)
		b._charge_cd = 999.0
		b._mortar_cd = 999.0
		b._squad_cd = 999.0
		game.player.position = center + Vector2(160, 0)
		game.player._iframes = 0.0
		before = game.player.damage_taken
		b._begin_barrage()
		var locked := b._targets.duplicate()
		tick(b, BossGeneral.MORTAR_WARNING - 0.05)
		check("general_no_early_mortar", game.player.damage_taken == before)
		if dodge: game.player.position += Vector2(0, 180)
		tick(b, 0.1)
		check("general_mortar_hit_or_dodge", game.player.damage_taken == before + (0.0 if dodge else 30.0) and b._targets == locked)
		b._targets.clear()
		b._timers.clear()
		b._struck.clear()
		game.player.position = center + Vector2(160, 0)
		game.player._iframes = 0.0
		before = game.player.damage_taken
		b._begin_shield_charge()
		var target := b._charge_target
		tick(b, 0.95)
		check("general_charge_warns", game.player.damage_taken == before and b._state == Boss.State.TELEGRAPH)
		if dodge: game.player.position += Vector2(0, 100)
		tick(b, 1.0)
		check("general_charge_fixed_hit_or_dodge", b._charge_target == target and game.player.damage_taken == before + (0.0 if dodge else 35.0))
	var count: int = game.horde.count
	game.horde.count = Horde.MAX_ENEMIES
	b._summon_squad()
	check("general_shared_horde_cap", game.horde.count == Horde.MAX_ENEMIES)
	game.horde.count = count
	b._begin_barrage()
	b.take_armored_damage(999999, Vector2.RIGHT, center, 1.0, true)
	check("general_death_cancels", not b.is_alive() and b._targets.is_empty() and b.armor_mask == 0)
	b.free()


static func _object7(game: Node, center: Vector2) -> void:
	var b := Boss.new()
	game.get_node("World").add_child(b)
	b.set_physics_process(false)
	b.player = game.player
	b.arena = game.ARENA
	b.start(center)
	game.player.global_position = center + Vector2(220, 0)
	b._choose_attack()
	check("object7_charge_telegraph", b._state == Boss.State.TELEGRAPH and b._telegraph_time == 1.0)
	tick(b, 1.0)
	check("object7_charge_400", b._state == Boss.State.CHARGE and Boss.CHARGE_SPEED == 400.0)
	b.start(center)
	b.take_damage(16000.0, Vector2.RIGHT, center)
	check("object7_armor_phase", b.hp == 12000.0 and b.phase == 2 and b._state == Boss.State.SHED)
	tick(b, Boss.SHED_TIME)
	check("object7_shed_recovers", b._state == Boss.State.WALK)
	b.start(center)
	game.player.global_position = center + Vector2(100, 0)
	b._last_attack = Boss.State.CHARGE
	b._choose_attack()
	check("object7_slam", b._state == Boss.State.SLAM)
	var damage_before: float = game.player.damage_taken
	tick(b, 1.0)
	check("object7_slam_25", game.player.damage_taken == damage_before + 25.0)
	b.start(center)
	game.player.global_position = center + Vector2(150, 0)
	b._charge_cd = 99.0
	b._choose_attack()
	check("object7_roar", b._state == Boss.State.ROAR)
	var calls := [0]
	b.roar.connect(func(n: int) -> void: calls[0] = n)
	tick(b, Boss.ROAR_TIME)
	check("object7_roar_15", calls[0] == 15)
	b.start(center)
	b.phase = 2
	game.player.global_position = center + Vector2(220, 0)
	b._choose_attack()
	check("object7_phase2_three_charges", b._charges_left == 3 and b._telegraph_time == 0.7)
	var charge_target := b._charge_target
	game.player.global_position += Vector2(0, 90)
	tick(b, 0.7)
	check("object7_charge_target_locked", b._state == Boss.State.CHARGE and b._charge_target == charge_target)
	b.free()


static func _campaign() -> void:
	var natural := CampaignRules.initial(812)
	for turn in 3:
		natural = CampaignRules.advance(natural, natural["offers"][0], "victory")["world"]
	check("general_naturally_discovered_turn3", natural["nests"]["general"]["discovered"] and CampaignDirector.nest_available(natural, "general"))
	for id: String in ["mother", "meat_mountain", "general"]:
		var state := CampaignRules.initial(812)
		state["turn"] = 4
		state["war"]["front"] = {}
		state["nests"][id]["discovered"] = true
		var region: String = CampaignCatalog.NESTS[id]["region_id"]
		var op := CampaignDirector._operation(state, region, "nest", 4, 2, RandomNumberGenerator.new())
		check("nest_valid_" + id, CampaignRules.valid_operation(op, state))
		var mission := CampaignRules.mission(state, op, 1)
		check("mission_boss_" + id, mission["boss"] == id)
		var result := CampaignRules.advance(state, op, "victory")
		check("only_target_nest_dies_" + id, not result["world"]["nests"][id]["alive"] and result["world"]["nests"]["object_7"]["alive"])
		check("no_war_victory_" + id, result["world"]["phase"] == "active")
		var mods := CampaignCatalog.region_modifiers(result["world"], region, ["elite_hunt", "acid_rain"])
		check("regional_effect_" + id, id == "general" or not mods.has("elite_hunt" if id == "mother" else "acid_rain"))
		var lost := CampaignRules.advance(state, op, "defeat")
		check("defeat_keeps_hive_" + id, lost["world"]["nests"][id]["alive"])
		var offers := CampaignDirector.generate(state)
		check("optional_offer_" + id, offers.any(func(o: Dictionary) -> bool: return o["type"] == "nest" and o["region_id"] == region))


## Вызывается штатным тестом кампании, где включены настоящие транзакции фасада.
static func campaign_transactions() -> void:
	for id: String in ["mother", "meat_mountain", "general"]:
		Meta.reset()
		var state := CampaignRules.initial(812)
		state["turn"] = 4
		state["war"]["front"] = {}
		state["nests"][id]["discovered"] = true
		state["offers"] = CampaignDirector.generate(state)
		Meta.campaign = state
		var config := Campaign.start_operation(state["offers"][2]["id"])
		CampaignTest.check("b2_pending_" + id, not config.is_empty() and config["boss"] == id)
		if config.is_empty():
			continue
		var stats := CampaignTest._stats(config, true)
		var report := Campaign.complete_operation(stats)
		var runs := Meta.runs
		var dna := Meta.dna
		var replay := Campaign.complete_operation(stats)
		CampaignTest.check("b2_transaction_once_" + id, report == replay and Meta.runs == runs and Meta.dna == dna and runs == 1)
		CampaignTest.check("b2_correct_nest_" + id, not Meta.campaign["nests"][id]["alive"] and Meta.campaign["nests"]["object_7"]["alive"] and Meta.campaign["phase"] == "active")
		CampaignTest.check("b2_save_roundtrip_" + id, Meta.from_dict(Meta.to_dict()) and CampaignRules.valid(Meta.campaign))
	Meta.reset()
	var final_state := CampaignRules.initial(812)
	final_state["turn"] = 7
	final_state["war"]["assault_unlocked"] = true
	final_state["war"]["front"] = {}
	final_state["nests"]["object_7"]["alive"] = false
	final_state["nests"]["hive_heart"]["discovered"] = true
	final_state["offers"] = CampaignDirector.generate(final_state)
	Meta.campaign = final_state
	var final_config := Campaign.start_operation(final_state["offers"][2]["id"])
	CampaignTest.check("b3_pending_real_heart", final_config.get("boss") == "hive_heart" and final_config.get("arena") == "quarantine")
	if not final_config.is_empty():
		Campaign.complete_operation(CampaignTest._stats(final_config, false))
		CampaignTest.check("b3_transaction_loss_keeps_retry", Meta.campaign["phase"] == "active" and Meta.campaign["nests"]["hive_heart"]["alive"])
		final_config = Campaign.start_operation(Meta.campaign["offers"][2]["id"])
		var stats := CampaignTest._stats(final_config, true)
		var report := Campaign.complete_operation(stats)
		var dna := Meta.dna
		var replay := Campaign.complete_operation(stats)
		CampaignTest.check("b3_final_reward_once", report == replay and Meta.runs == 2 and Meta.dna == dna and Meta.campaign["phase"] == "victory")
		CampaignTest.check("b3_final_save_roundtrip", Meta.from_dict(Meta.to_dict()) and CampaignRules.valid(Meta.campaign) and Meta.campaign["phase"] == "victory")
	Meta.reset()
