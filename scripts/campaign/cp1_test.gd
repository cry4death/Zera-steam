class_name CP1Test
extends RefCounted
## Модельные боты: вероятность успеха задаётся явно, бой не симулируется.


static func units() -> void:
	var state := CampaignRules.initial(812)
	CampaignTest.check("cp1_no_first_turn_final", not CampaignDirector.nest_available(state, "object_7") and state["offers"][2]["type"] == "clearance")
	var before := state.duplicate(true)
	for op: Dictionary in state["offers"]:
		for outcome: String in ["victory", "defeat"]:
			var forecast := CampaignRules.advance(state, op, outcome, true)
			var commit := CampaignRules.advance(state, op, outcome)
			CampaignTest.check("cp1_forecast_%s_%s" % [op["type"], outcome], forecast["world"]["regions"] == commit["world"]["regions"] and forecast["world"]["war"] == commit["world"]["war"] and forecast["report"] == commit["report"])
	CampaignTest.check("cp1_preview_no_mutation", state == before)
	var strike: Dictionary = state["war"]["front"]
	state["turn"] = 2
	state["offers"] = CampaignDirector.generate(state)
	var defend := {"region_id": strike["target"], "type": "extract"}
	var success := CampaignRules.advance(state, defend, "victory")
	var failed := CampaignRules.advance(state, defend, "defeat")
	CampaignTest.check("cp1_front_cancel_or_land", success["report"]["events"].any(func(s: String) -> bool: return s.begins_with("Удар сорван")) and failed["report"]["events"].any(func(s: String) -> bool: return s.begins_with("Удар:")))
	CampaignTest.check("cp1_front_advances_only_at_deadline", int(success["world"]["war"]["front"]["due_turn"]) == 6 and int(failed["world"]["war"]["front"]["due_turn"]) == 6)
	var post := {"region_id": "north_america", "type": "clearance"}
	state = CampaignRules.advance(before, post, "victory")["world"]
	var repeated: Dictionary = CampaignRules.advance(state, post, "victory")["world"]
	CampaignTest.check("cp1_outpost_unique_persistent", repeated["war"]["outposts"] == ["north_america"])
	var sample := {"region_id": "east_asia", "type": "extract"}
	state = CampaignRules.advance(state, sample, "victory")["world"]
	state = CampaignRules.advance(state, sample, "victory")["world"]
	CampaignTest.check("cp1_samples_unique", state["war"]["samples"] == ["east_asia"])
	state["regions"]["north_america"]["infection"] = 79
	state = CampaignRules.advance(state, post, "defeat")["world"]
	CampaignTest.check("cp1_outpost_lost_at_80", not state["war"]["outposts"].has("north_america"))
	state = before.duplicate(true)
	state["turn"] = 5
	state["war"]["front"] = CampaignWar.front(state)
	state["war"]["outposts"] = ["north_america", "west_europe", "siberia"]
	state["war"]["samples"] = ["east_asia", "south_asia"]
	state = CampaignRules.advance(state, post, "victory")["world"]
	CampaignTest.check("cp1_final_unlock_six_operations", state["war"]["assault_unlocked"] and state["offers"][2]["type"] == "nest" and CampaignRules.valid(state))
	CampaignTest.check("cp1_final_can_delay_to_defend_front", state["offers"][1]["region_id"] == state["war"]["front"]["target"])
	var dead: Dictionary = CampaignRules.advance(state, state["offers"][2], "victory")["world"]
	CampaignTest.check("cp1_final_stops_front", dead["war"]["front"].is_empty() and not dead["nests"]["object_7"]["alive"])
	CampaignTest.check("b3_object_opens_heart_not_victory", dead["phase"] == "active" and dead["nests"]["hive_heart"]["discovered"] and dead["offers"][2]["region_id"] == "south_asia" and dead["offers"][2]["name"] == "Сердце Улья")
	var retry: Dictionary = CampaignRules.advance(dead, dead["offers"][2], "defeat")["world"]
	CampaignTest.check("b3_final_defeat_retry", retry["phase"] == "active" and retry["nests"]["hive_heart"]["alive"] and retry["offers"][2]["type"] == "nest" and CampaignRules.valid(retry))
	for id: String in CampaignCatalog.REGIONS:
		retry["regions"][id]["infection"] = 100
	retry["war"]["outposts"] = []
	retry["offers"] = CampaignDirector.generate(retry)
	var retry_lost: Dictionary = CampaignRules.advance(retry, retry["offers"][2], "defeat")["world"]
	CampaignTest.check("b3_final_retry_even_lost_region", retry["offers"][2]["type"] == "nest" and CampaignRules.valid(retry) and retry_lost["phase"] == "active" and CampaignRules.valid(retry_lost))
	var final: Dictionary = CampaignRules.advance(retry_lost, retry_lost["offers"][2], "victory")["world"]
	CampaignTest.check("b3_heart_ends_war_even_high_infection", final["phase"] == "victory" and not final["nests"]["hive_heart"]["alive"] and CampaignRules.valid(final) and not CampaignDirector.nest_available(final, "hive_heart"))
	Meta.reset()
	Meta.apply_preset("maxed")
	Meta.settings["reduce_motion"] = true
	Meta.crates = 17
	Meta.military_crates = 8
	state = CampaignTest._legacy(913)
	state["run_serial"] = 1
	state["pending_operation"] = CampaignRules.mission(state, state["offers"][2], 1)
	state.erase("war")
	state["schema_version"] = 2
	var profile := Meta.to_dict()
	profile["version"] = 4
	profile["campaign"] = state
	# JSON возвращает номер схемы как float.
	var loaded := Meta.from_dict(JSON.parse_string(JSON.stringify(profile)))
	var migrated := Meta.to_dict()
	var upgraded: Dictionary = migrated["campaign"].duplicate(true)
	upgraded.erase("war")
	upgraded["schema_version"] = 2
	migrated["version"] = 4
	migrated["campaign"] = upgraded
	CampaignTest.check("cp1_v4_all_profile_fields_pending_offers_preserved", loaded and not Meta.campaign_recovered and profile == migrated and CampaignRules.valid(Meta.campaign))
	var corrupt := Meta.campaign.duplicate(true)
	corrupt["war"]["samples"] = ["unknown"]
	CampaignTest.check("cp1_corrupt_progress_rejected", not CampaignRules.valid(corrupt))
	corrupt = Meta.campaign.duplicate(true)
	corrupt["war"]["front"]["due_turn"] = "tomorrow"
	CampaignTest.check("cp1_corrupt_front_rejected", not CampaignRules.valid(corrupt))
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://design/tasks/reports/cp1_v4_fixture.json"))
	loaded = Meta.from_dict(fixture)
	migrated = Meta.to_dict()
	upgraded = migrated["campaign"].duplicate(true)
	upgraded.erase("war")
	upgraded["schema_version"] = 2
	migrated["version"] = 4
	migrated.erase("tree_gates") # поле T1 (схема 6), в фикстуре v4 его нет
	migrated.erase("class_id") # поля T2 (схема 7), проверяются в --class-tree-test
	migrated.erase("class_trees")
	migrated["campaign"] = upgraded
	var expected := fixture.duplicate(true)
	# Новые настройки добавляются, значения старых полей сохраняются.
	expected["settings"] = Meta.clean_settings(expected.get("settings", {}))
	# Каталог расширяется: старый порядок сохраняется, новые серийные модели доступны всем.
	for id: String in WeaponDefs.MODEL_ORDER:
		if WeaponDefs.MODELS[id]["rarity"] == WeaponDefs.Rarity.SERIAL and not expected["owned"].has(id):
			expected["owned"].append(id)
	CampaignTest.check("cp1_actual_c6_v4_fixture_preserved", loaded and not Meta.campaign_recovered and CampaignRules.normalized(expected) == CampaignRules.normalized(migrated))
	if CampaignRules.normalized(expected) != CampaignRules.normalized(migrated):
		print("CP1MIG loaded=%s recovered=%s" % [loaded, Meta.campaign_recovered])
		for key: String in fixture:
			if CampaignRules.normalized(fixture[key], key) != CampaignRules.normalized(migrated.get(key), key):
				print("CP1MIG changed=" + key)
	var old_path: String = Meta.save_path
	var test_path := "res://design/tasks/reports/cp1_userdata/fixtures/v4_roundtrip.json"
	Meta._write_atomic(test_path, JSON.stringify(fixture))
	Meta.save_path = test_path
	Meta.persist = true
	var disk_loaded := Meta.load_save()
	var disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(test_path))
	CampaignTest.check("cp1_v4_disk_rewritten_current_no_profile_loss", disk_loaded and not Meta.campaign_recovered and int(disk["version"]) == Meta.SAVE_VERSION and CampaignRules.normalized(disk) == CampaignRules.normalized(Meta.to_dict()))
	Meta.persist = false
	Meta.save_path = old_path
	var rescued := true
	for lost_count in 3:
		state = CampaignRules.initial(107 + lost_count)
		for id: String in CampaignCatalog.REGIONS:
			state["regions"][id]["infection"] = 60
		for id: String in CampaignCatalog.KEY_REGIONS.slice(0, lost_count):
			state["regions"][id]["infection"] = 85
		state["offers"] = CampaignDirector.generate(state)
		for turn in 40:
			if state["phase"] != "active":
				break
			state = CampaignRules.advance(state, choose(state), "victory")["world"]
		rescued = rescued and state["phase"] == "victory"
	CampaignTest.check("cp1_recovery_zero_one_two_keys_lost", rescued)
	Meta.reset()


static func choose(state: Dictionary, strategy: int = 0, rng: RandomNumberGenerator = null) -> Dictionary:
	if strategy == 3:
		return state["offers"][rng.randi_range(0, 2)]
	if strategy == 5:
		return state["offers"][0]
	var best: Dictionary = state["offers"][0]
	var score := -INF
	for op: Dictionary in state["offers"]:
		var next: Dictionary = CampaignRules.advance(state, op, "victory", true)["world"]
		var value := (CampaignRules.average(state) - CampaignRules.average(next)) * 8.0
		value += (CampaignRules.lost_keys(state) - CampaignRules.lost_keys(next)) * 40.0
		if op["type"] == "nest" and op["region_id"] in ["east_europe", "south_asia"]:
			value += 100.0
		if not state["war"]["assault_unlocked"]:
			if op["type"] in ["clearance", "reclaim"] and state["war"]["outposts"].size() < 3 and not state["war"]["outposts"].has(op["region_id"]):
				value += 32.0
			if op["type"] == "extract" and state["war"]["samples"].size() < 2 and not state["war"]["samples"].has(op["region_id"]):
				value += 35.0
		if strategy == 4:
			value = float(op["reward"]["dna_mul"]) + float(op["reward"]["extra_crate_chance"])
		if value > score:
			score = value
			best = op
	return best


static func simulate() -> void:
	var names := ["perfect", "tactical", "learning", "random", "reward", "safe", "frequent_defeat"]
	var arc: Array = []
	var curves: Array = []
	var invalid := 0
	print("CP1SIM campaigns=1400 limit=60; model outcomes, not combat; capped=unfinished")
	print("strategy | win | defeat | capped | median_turn | p90_turn | mean_final_infection | object_turn | heart_turn")
	for strategy in names.size():
		var wins := 0
		var defeats := 0
		var lengths: Array[int] = []
		var final_sum := 0.0
		var boss_sum := 0.0
		var boss_count := 0
		var heart_sum := 0.0
		var heart_count := 0
		var curve: Array[Dictionary] = []
		for turn in 60:
			curve.append({"strategy": names[strategy], "turn": turn + 1, "count": 0, "infection_sum": 0.0, "threat_sum": 0.0, "unlocks": 0, "bosses": 0, "hearts": 0})
		for sample in 200:
			var state := CampaignRules.initial(1000 + sample)
			var rng := RandomNumberGenerator.new()
			rng.seed = 90000 + sample * 8 + strategy
			for turn in 60:
				if state["phase"] in ["victory", "defeat"]:
					break
				var op := choose(state, strategy, rng)
				var chance: float = [1.0, 0.95, 0.78, 0.90, 0.90, 0.95, 0.38][strategy]
				if strategy != 0:
					chance -= 0.035 * (int(op["threat"]) - 1)
				var outcome := "victory" if rng.randf() < chance else "defeat"
				var was_unlocked: bool = state["war"]["assault_unlocked"]
				state = CampaignRules.advance(state, op, outcome)["world"]
				curve[turn]["count"] += 1
				curve[turn]["infection_sum"] += CampaignRules.average(state)
				curve[turn]["threat_sum"] += int(op["threat"])
				if not was_unlocked and state["war"]["assault_unlocked"]:
					curve[turn]["unlocks"] += 1
				if op["type"] == "nest" and op["region_id"] == "east_europe" and outcome == "victory":
					curve[turn]["bosses"] += 1
				if not CampaignRules.valid(state):
					invalid += 1
				if op["type"] == "nest" and op["region_id"] == "east_europe" and outcome == "victory":
					boss_sum += int(state["turn"])
					boss_count += 1
				if op["type"] == "nest" and op["region_id"] == "south_asia" and outcome == "victory":
					heart_sum += int(state["turn"])
					heart_count += 1
					curve[turn]["hearts"] += 1
				if sample == 0 and strategy in [0, 1, 2, 5]:
					arc.append({"strategy": names[strategy], "turn": state["turn"], "infection": CampaignRules.average(state), "threat": op["threat"], "type": op["type"], "region": op["region_id"], "outcome": outcome, "unlocked": state["war"]["assault_unlocked"], "phase": state["phase"]})
			wins += 1 if state["phase"] == "victory" else 0
			defeats += 1 if state["phase"] == "defeat" else 0
			lengths.append(int(state["turn"]))
			final_sum += CampaignRules.average(state)
		lengths.sort()
		curves.append_array(curve)
		print("%s | %d | %d | %d | %d | %d | %.2f | %.2f (%d) | %.2f (%d)" % [names[strategy], wins, defeats, 200 - wins - defeats, lengths[99], lengths[179], final_sum / 200.0, boss_sum / maxf(1.0, boss_count), boss_count, heart_sum / maxf(1.0, heart_count), heart_count])
		if strategy == 0:
			CampaignTest.check("cp1_perfect_player_can_win_all", wins == 200 and defeats == 0)
		if strategy == 6:
			CampaignTest.check("cp1_failures_have_a_price", defeats > 0)
	CampaignTest.check("cp1_1400_campaigns_valid_no_deadlocks", invalid == 0)
	var file := FileAccess.open("res://design/tasks/reports/b3_arc.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"trace": arc, "curves": curves}, "\t"))
