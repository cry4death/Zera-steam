class_name CampaignTest
extends RefCounted
## Headless-проверки: только память и res://design/tasks/reports/cp1_userdata/fixtures/c1_*.

static var checks := 0
static var failures := 0


static func check(label: String, condition: bool) -> void:
	checks += 1
	if not condition:
		failures += 1
	print("CAMPAIGNTEST %s=%s" % [label, condition])


static func run(game: Node) -> bool:
	game.process_mode = Node.PROCESS_MODE_DISABLED
	checks = 0
	failures = 0
	Meta.persist = false
	_units()
	_c6_units()
	_c6_sockets(game)
	_integration(game)
	BossTest.campaign_transactions()
	# Дадим дереву обработать удаление тестового UI до длинной симуляции.
	await game.get_tree().process_frame
	CP1Test.units()
	if not OS.get_cmdline_user_args().has("--cp1-units"):
		CP1Test.simulate()
	print("CAMPAIGNTEST checks=%d failures=%d" % [checks, failures])
	print("CAMPAIGNTEST ok=%s" % (failures == 0))
	return failures == 0


## Прежние C6-контракты проверяются с уже открытым штурмом.
static func _legacy(seed_value: int) -> Dictionary:
	var state := CampaignRules.initial(seed_value)
	state["war"]["assault_unlocked"] = true
	state["offers"] = CampaignDirector.generate(state)
	return state


static func _flat(infection: int) -> Dictionary:
	var state := CampaignRules.initial(7)
	for id: String in state["regions"]:
		state["regions"][id]["infection"] = infection
	state["nests"]["object_7"]["alive"] = false
	return state


static func _units() -> void:
	var state := _legacy(1234)
	var op: Dictionary = state["offers"][0]
	var bounded := true
	for infection: int in [0, 1, 19, 20, 59, 60, 79, 80, 99, 100]:
		for outcome: String in ["victory", "partial", "defeat"]:
			var test := _flat(infection)
			var next: Dictionary = CampaignRules.advance(test, op, outcome)["world"]
			for id: String in next["regions"]:
				bounded = bounded and int(next["regions"][id]["infection"]) >= 0 and int(next["regions"][id]["infection"]) <= 100
	check("unit1_clamp", bounded)
	var stages_ok := true
	var edges := [0, 19, 20, 39, 40, 59, 60, 79, 80, 100]
	for i in edges.size():
		stages_ok = stages_ok and CampaignRules.stage(edges[i]) == floori(i / 2.0)
	check("unit2_stage_boundaries", stages_ok)
	var reversed := state.duplicate(true)
	var keys: Array = reversed["regions"].keys()
	keys.reverse()
	reversed["regions"] = {}
	for id: String in keys:
		reversed["regions"][id] = state["regions"][id].duplicate(true)
	var next_a := CampaignRules.advance(state, op, "victory")
	var next_b := CampaignRules.advance(reversed, op, "victory")
	check("unit3_snapshot_order_and_input_immutable", next_a == next_b and state == _legacy(1234))
	var snapshot_test := CampaignRules.advance(state, {"region_id": "east_europe", "type": "clearance"}, "victory")
	check("unit3_pressure_after_mission_effect", int(snapshot_test["world"]["regions"]["west_europe"]["infection"]) == 26)
	var nest_op: Dictionary = state["offers"][2]
	var killed: Dictionary = CampaignRules.advance(state, nest_op, "victory")["world"]
	var alive := state.duplicate(true)
	alive["regions"]["east_europe"]["infection"] = 20
	var dead := alive.duplicate(true)
	dead["nests"]["object_7"]["alive"] = false
	var difference := int(CampaignRules.pressure(alive, "east_europe")["growth"]) - int(CampaignRules.pressure(dead, "east_europe")["growth"])
	for turn in 10:
		killed = CampaignRules.advance(killed, op, "defeat")["world"]
	check("unit4_nest_permanent_no_pressure", not killed["nests"]["object_7"]["alive"] and difference == int(CampaignCatalog.BALANCE["nest_pressure"]))
	var suppressed := _flat(40)
	suppressed["regions"]["north_america"]["suppressed_turns"] = 2
	var snapshots: Array[int] = []
	var remaining: Array[int] = []
	var other := {"region_id": "east_asia", "type": "clearance"}
	for turn in 3:
		suppressed = CampaignRules.advance(suppressed, other, "defeat")["world"]
		snapshots.append(int(suppressed["regions"]["north_america"]["infection"]))
		remaining.append(int(suppressed["regions"]["north_america"]["suppressed_turns"]))
	check("unit5_suppression_turns_1_2_3", snapshots == [40, 40, 41] and remaining == [1, 0, 0])
	var applied: Dictionary = CampaignRules.advance(_flat(60), {"region_id": "north_america", "type": "clearance"}, "victory")["world"]
	check("unit5_new_suppression_includes_current", int(applied["regions"]["north_america"]["suppressed_turns"]) == 1 and int(applied["regions"]["north_america"]["infection"]) == 32)
	check("unit6_generator_deterministic", CampaignDirector.generate(state) == CampaignDirector.generate(state))
	var offers_ok := true
	var deterministic := true
	for seed in 100:
		var campaign := _legacy(seed)
		var twin := campaign.duplicate(true)
		for turn in 4:
			var proposals := CampaignDirector.generate(campaign)
			offers_ok = offers_ok and proposals.size() == 3 and int(proposals[0]["threat"]) <= 2 and proposals[2]["type"] == "nest"
			for offer: Dictionary in proposals:
				offers_ok = offers_ok and CampaignRules.valid_operation(offer, campaign) and CampaignCatalog.compatible(offer["modifiers"])
			campaign = CampaignRules.advance(campaign, proposals[0], "victory")["world"]
			twin = CampaignRules.advance(twin, twin["offers"][0], "victory")["world"]
			deterministic = deterministic and campaign == twin
	check("unit7_offer_quotas_and_compatibility", offers_ok)
	check("unit6_world_replay", deterministic)
	var lost := _flat(100)
	lost["offers"] = CampaignDirector.generate(lost)
	check("unit8_lost_still_accessible", lost["offers"].size() == 3 and int(lost["offers"][0]["threat"]) == 5 and lost["offers"][0]["type"] == "reclaim")
	check("unit8_all_lost_campaign_defeat", CampaignRules.phase(lost) == "defeat")
	var single := _flat(0)
	single["regions"]["north_america"]["infection"] = 100
	single["offers"] = CampaignDirector.generate(single)
	check("c6_reclaim_always_offered", single["offers"][1]["type"] == "reclaim" and single["offers"][1]["region_id"] == "north_america")
	var reclaim_rng := RandomNumberGenerator.new()
	var reclaim := CampaignDirector._operation(single, "north_america", "clearance", 1, 0, reclaim_rng)
	var returned: Dictionary = CampaignRules.advance(single, reclaim, "victory")["world"]
	check("unit8_single_lost_recoverable", returned["regions"]["north_america"]["infection"] < 80)
	var graph_ok := true
	for id: String in CampaignCatalog.REGIONS:
		for neighbor: String in CampaignCatalog.REGIONS[id]["neighbors"]:
			graph_ok = graph_ok and CampaignCatalog.REGIONS.has(neighbor) and CampaignCatalog.REGIONS[neighbor]["neighbors"].has(id)
	var remote := _flat(0)
	remote["regions"]["east_europe"]["infection"] = 70
	check("unit9_explicit_symmetric_graph", graph_ok and int(CampaignRules.pressure(remote, "north_america")["growth"]) == 0 and int(CampaignRules.pressure(remote, "siberia")["growth"]) == int(CampaignCatalog.BALANCE["neighbor_pressure"]))
	check("unit10_boss_unlock_content_gate", CampaignDirector.nest_available(state, "object_7") and not CampaignDirector.nest_available(killed, "object_7") and not CampaignDirector.nest_available(state, "hive_heart") and not CampaignDirector.nest_available(state, "mother"))
	var invalid := state.duplicate(true)
	invalid["regions"]["siberia"]["infection"] = 101
	check("validation_range", not CampaignRules.valid(invalid))
	invalid = state.duplicate(true)
	invalid["regions"]["siberia"]["infection"] = 3.5
	check("validation_fraction", not CampaignRules.valid(invalid))
	invalid = state.duplicate(true)
	invalid["regions"]["unknown"] = invalid["regions"]["siberia"]
	check("validation_unknown_region", not CampaignRules.valid(invalid))
	invalid = state.duplicate(true)
	invalid["offers"][0]["type"] = "teleport"
	check("validation_unknown_template", not CampaignRules.valid(invalid))
	check("validation_initial", CampaignRules.valid(state))
	var json_world: Dictionary = JSON.parse_string(JSON.stringify(state))
	check("validation_json_roundtrip", CampaignRules.valid(json_world))


static func _stats(config: Dictionary, victory: bool) -> Dictionary:
	return {"run_id": config["run_id"], "operation_id": config["operation_id"], "region_id": config["region_id"], "type": config["type"],
		"victory": victory, "outcome": "victory" if victory else "defeat", "dna_total": 100,
		"dna_mult": 1.0, "dna_lines": [["Образцы", 100]], "crates": 2, "military_crates": 1}


static func _integration(game: Node) -> void:
	Meta.reset()
	Campaign.new_campaign(456)
	Meta.campaign = _legacy(456)
	var before_save := Meta.save_calls
	var config := Campaign.start_operation(Campaign.offers()[2]["id"])
	check("start_persisted_pending_before_scene", not config.is_empty() and Meta.save_calls == before_save + 1 and CampaignRules.valid(Campaign.world()))
	var stats := _stats(config, true)
	before_save = Meta.save_calls
	var report := Campaign.complete_operation(stats)
	check("integration1_victory_one_save_rewards_world", not report.is_empty() and Meta.runs == 1 and Meta.dna == int(report["stats"]["dna_total"]) and Meta.dna >= 100 and Meta.crates == int(report["stats"]["crates"]) and Meta.military_crates == 1 and int(Campaign.world()["turn"]) == 1 and Meta.save_calls == before_save + 1)
	var saved := Meta.to_dict()
	var replay := Campaign.complete_operation(stats)
	check("integration1_idempotent_same_report", report == replay and Meta.to_dict() == saved and Meta.save_calls == before_save + 1)
	var old_saved := saved.duplicate(true)
	old_saved["version"] = 3
	old_saved["campaign"]["schema_version"] = 1
	check("c6_migrated_completed_reward_once", Meta.from_dict(old_saved) and Campaign.complete_operation(stats) == report and Meta.runs == 1 and Meta.dna == saved["dna"])
	check("cp1_restore_current_profile_after_legacy_fixture", Meta.from_dict(saved))
	check("report_full_changes_causes_priority", report["changes"].size() > 0 and report["events"].size() <= 3 and report["events"][0].contains("Сердцу Улья") and report["changes"][0]["causes"].size() > 0)
	# Проверяем настоящий RunResults.open дважды, включая удаление pending.
	var results := RunResults.new()
	game.add_child(results)
	results.open(stats)
	results.open(stats)
	check("integration3_results_reopen", Meta.to_dict() == saved and results._stats["dna_total"] == Meta.dna)
	Campaign.continue_campaign()
	config = Campaign.start_operation(Campaign.offers()[0]["id"])
	var defeat := _stats(config, false)
	var expected := CampaignRules.advance(Campaign.world(), config, "defeat")
	var prior_dna := Meta.dna
	var prior_runs := Meta.runs
	before_save = Meta.save_calls
	results.open(defeat)
	results.open(defeat)
	check("integration2_defeat_once", Meta.dna == prior_dna + 100 and Meta.runs == prior_runs + 1 and Campaign.world()["regions"] == expected["world"]["regions"] and Meta.save_calls == before_save + 1)
	config = Campaign.start_operation(Campaign.offers()[0]["id"])
	var raw := _stats(config, true)
	for key: String in ["run_id", "operation_id", "region_id", "type", "outcome"]:
		raw.erase(key)
	prior_runs = Meta.runs
	results.open(raw)
	var after_raw := Meta.to_dict()
	results.open(raw)
	check("integration3_legacy_result_gets_run_id_once", raw.get("run_id") == config["run_id"] and Meta.runs == prior_runs + 1 and Meta.to_dict() == after_raw)
	check("idempotent_older_run_report", Campaign.complete_operation(stats) == report and Meta.to_dict() == after_raw)
	results.queue_free()
	# Профиль с настоящим арсеналом, деревом, настройками и избранным.
	Meta.apply_preset("maxed")
	Meta.crates = 17
	Meta.military_crates = 8
	Meta.favorite[WeaponDefs.Base.RIFLE] = "m4"
	Meta.settings["auto_fire"] = false
	Meta.settings["world"] = 0.37
	var profile := Meta.to_dict()
	var migration_ok := true
	for version: int in [1, 2]:
		var legacy := profile.duplicate(true)
		legacy["version"] = version
		legacy.erase("campaign")
		var loaded := Meta.from_dict(legacy)
		var migrated := Meta.to_dict()
		migrated.erase("campaign")
		migrated["version"] = version
		migration_ok = migration_ok and loaded and not Meta.campaign_recovered and migrated == legacy
	check("integration5_v1_v2_profile_preserved", migration_ok)
	DirAccess.make_dir_recursive_absolute("res://design/tasks/reports/cp1_userdata/fixtures")
	var test_path := "res://design/tasks/reports/cp1_userdata/fixtures/c1_migration.json"
	var legacy := profile.duplicate(true)
	legacy["version"] = 2
	legacy.erase("campaign")
	Meta._write_atomic(test_path, JSON.stringify(legacy))
	Meta.save_path = test_path
	Meta.persist = true
	var loaded := Meta.load_save()
	check("integration5_file_migration_not_corrupt", loaded and not Meta.campaign_recovered and Meta.last_error.is_empty() and int(JSON.parse_string(FileAccess.get_file_as_string(test_path))["version"]) == Meta.SAVE_VERSION)
	var bad := profile.duplicate(true)
	bad["campaign"]["regions"]["east_europe"]["infection"] = -500
	Meta._write_atomic(test_path, JSON.stringify(bad))
	loaded = Meta.load_save()
	var recovered := Meta.to_dict()
	recovered.erase("campaign")
	var original := profile.duplicate(true)
	original.erase("campaign")
	var backup_found := false
	for file: String in DirAccess.get_files_at("res://design/tasks/reports/cp1_userdata/fixtures"):
		if file.begins_with("c1_migration.json.campaign-bad-"):
			backup_found = backup_found or FileAccess.get_file_as_string("res://design/tasks/reports/cp1_userdata/fixtures/" + file) == JSON.stringify(bad)
	check("integration6_corrupt_campaign_backup_profile_intact", loaded and Meta.campaign_recovered and recovered == original and backup_found and Meta.last_error.contains("блок campaign повреждён"))
	# Сохранённый pending переживает чтение, затем база снимает его без награды/хода.
	config = Campaign.start_operation(Campaign.offers()[0]["id"])
	var snapshot := Meta.to_dict()
	loaded = Meta.load_save()
	check("integration4_pending_and_offers_reload", loaded and Meta.to_dict() == snapshot and Campaign.pending() == config)
	var message := Campaign.abandon_pending()
	check("integration8_abandoned_no_commit", message.contains("операция не засчитана") and Campaign.pending().is_empty() and Meta.dna == int(snapshot["dna"]) and Meta.runs == int(snapshot["runs"]) and Campaign.world()["turn"] == snapshot["campaign"]["turn"] and Campaign.world()["offers"] == snapshot["campaign"]["offers"])
	var again := Campaign.start_operation(Campaign.offers()[0]["id"])
	check("retry_new_run_id", again["run_id"] != config["run_id"])
	var invalid_stats := _stats(again, true)
	invalid_stats["dna_total"] = -1
	var untouched := Meta.to_dict()
	check("commit_invalid_rewards_rejected", Campaign.complete_operation(invalid_stats).is_empty() and Meta.to_dict() == untouched)
	invalid_stats = _stats(again, true)
	invalid_stats["run_id"] = "wrong-run"
	check("commit_wrong_run_rejected", Campaign.complete_operation(invalid_stats).is_empty() and Meta.to_dict() == untouched)
	invalid_stats = _stats(again, true)
	invalid_stats["outcome"] = "partial"
	check("commit_partial_requires_explicit_objective", Campaign.complete_operation(invalid_stats).is_empty() and Meta.to_dict() == untouched)
	var flags_ok := true
	for flag: String in Meta.TEST_FLAGS:
		if flag.begins_with("--campaign") or flag.begins_with("--c6") or flag == "--globe-test":
			continue
		flags_ok = flags_ok and Meta.is_test_run(PackedStringArray([flag])) and not Campaign.enabled(PackedStringArray([flag]))
	check("integration7_all_legacy_test_flags_bypass", flags_ok and Meta.is_test_run(PackedStringArray(["--campaign-test"])) and Meta.is_test_run(PackedStringArray(["--campaign-op=first"])))
	# Ошибка записи не запускает бой и не теряет старый pending.
	Campaign.abandon_pending()
	Meta.save_path = "res://design/tasks/reports/cp1_userdata/fixtures/c1_missing_directory/save.json"
	var prior_world := Campaign.world()
	check("failed_start_no_scene_config", Campaign.start_operation(Campaign.offers()[0]["id"]).is_empty() and Campaign.world() == prior_world and not Meta.last_save_ok)
	Meta.persist = false
	Meta.save_path = Meta.SAVE_PATH
	Meta.reset()
	Meta.apply_preset("maxed")
	var meta_before := Meta.to_dict()
	meta_before.erase("campaign")
	Campaign.new_campaign(999)
	var meta_after := Meta.to_dict()
	meta_after.erase("campaign")
	check("new_campaign_keeps_profile", meta_before == meta_after and Campaign.world()["seed"] == 999 and Campaign.world()["turn"] == 0)


static func _c6_units() -> void:
	var state := _legacy(706)
	check("c6_three_distinct_objectives", state["offers"][0]["objective"] == "destroy_node" and state["offers"][1]["objective"] == "extract_sample" and state["offers"][2]["objective"] == "kill_boss")
	var rng := RandomNumberGenerator.new()
	var combat_ok := true
	for infection: int in [0, 19, 20, 39, 40, 59, 60, 79, 80, 99, 100]:
		var sample := state.duplicate(true)
		sample["regions"]["east_europe"]["infection"] = infection
		var profile: Dictionary = CampaignCatalog.STAGE_COMBAT[CampaignRules.stage(infection)]
		for type: String in ["clearance", "extract"]:
			var op := CampaignDirector._operation(sample, "east_europe", type, 1, 0, rng)
			combat_ok = combat_ok and CampaignRules.valid_operation(op, sample) and int(op["threat"]) >= int(profile["threat"])
			for modifier: String in profile["modifiers"]:
				combat_ok = combat_ok and op["modifiers"].has(modifier)
			if infection == 100:
				combat_ok = combat_ok and op["type"] == "reclaim" and op["threat"] == 5
	check("c6_stage_combat_edges_reclaim", combat_ok)
	var killed: Dictionary = CampaignRules.advance(state, state["offers"][2], "victory")["world"]
	check("b3_object7_is_penultimate", killed["phase"] == "active" and CampaignRules.average(killed) < 35.0 and CampaignRules.valid(killed))
	var no_boss := true
	for op: Dictionary in killed["offers"]:
		no_boss = no_boss and CampaignRules.mission(killed, op, 1)["boss"] != "object_7"
	check("c6_destroyed_object7_never_offered", no_boss)
	var high := _flat(50)
	check("c6_boss_dead_alone_no_victory", CampaignRules.phase(high) == "active")
	for id: String in CampaignCatalog.KEY_REGIONS.slice(0, 2):
		high["regions"][id]["infection"] = 80
	check("c6_warning_two_keys", CampaignRules.lost_keys(high) == 2 and CampaignRules.phase(high) == "active")
	high["regions"][CampaignCatalog.KEY_REGIONS[2]]["infection"] = 80
	high["phase"] = CampaignRules.phase(high)
	high["offers"] = CampaignDirector.generate(high)
	check("c6_defeat_three_keys_no_launch", high["phase"] == "defeat" and high["offers"].is_empty() and CampaignRules.valid(high))
	var legacy := state.duplicate(true)
	legacy["schema_version"] = 1
	legacy["offers"][0]["objective"] = "kill_boss"
	legacy["pending_operation"] = CampaignRules.mission(legacy, legacy["offers"][0], 0)
	var migrated: Dictionary = CampaignRules.migrate(legacy)
	check("c6_migrate_v1_regenerate_cancel_pending", CampaignRules.valid(migrated) and migrated["pending_operation"].is_empty() and migrated["offers"] == CampaignDirector.generate(migrated) and migrated["turn"] == state["turn"])
	Meta.reset()
	var profile := Meta.to_dict()
	profile["version"] = 3
	profile["campaign"] = legacy
	profile["dna"] = 772
	check("c6_meta_v3_migration_keeps_dna", Meta.from_dict(profile) and Meta.dna == 772 and not Meta.campaign_recovered and Meta.campaign["schema_version"] == 3)
	legacy["regions"]["east_europe"]["infection"] = -1
	check("c6_corrupt_legacy_rejected", not CampaignRules.valid(CampaignRules.migrate(legacy)))
	var extraction: Dictionary = state["offers"][1]
	var win := CampaignRules.advance(state, extraction, "victory")
	var loss := CampaignRules.advance(state, extraction, "defeat")
	check("c6_extract_reward_weak_effect_death_fails", extraction["reward"]["extra_crate_chance"] >= 0.25 and extraction["effects"]["win"]["infection"] == -10 and win["world"] != loss["world"] and not extraction["supports_partial"])


static func _c6_sockets(game: Node) -> void:
	var ok := true
	for id: String in MapLoader.IDS:
		var data := MapLoader.load_map(id)
		for seed_value: int in [0, 706, 2147483647]:
			var obstacles := Obstacles.new()
			game.add_child(obstacles)
			obstacles.setup(Rect2(Vector2.ZERO, data["size"]), MapLoader.layout(data, seed_value))
			obstacles.set_physics_process(false)
			while obstacles.nav_completed == 0:
				obstacles.navigation_step(0.0, data["start"])
			for type: String in ["node", "sample", "evac"]:
				var radius := 60.0 if type == "evac" else 36.0
				for point: Array in data["objective_sockets"][type]:
					var at := obstacles.free_point(MapLoader.point(point), radius)
					ok = ok and not obstacles.contains(at, radius) and obstacles.distance[obstacles.cell_at(at)] != Obstacles.NO_PATH
			obstacles.queue_free()
	check("c6_sockets_three_maps_three_seeds_reachable", ok)
