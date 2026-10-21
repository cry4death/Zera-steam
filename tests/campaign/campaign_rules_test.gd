extends GdUnitTestSuite
## Правила глобальной кампании: этапы заражения, ход войны, проверка и миграция сохранения.
## Требования — design/CAMPAIGN.md §6 и комментарии CampaignRules. Сиды фиксированы.

const SEED := 20261017


## Мир с открытым штурмом Объекта-7 — как сохранения до появления войны (так же строит campaign_test.gd).
func _unlocked(seed_value: int) -> Dictionary:
	var state := CampaignRules.initial(seed_value)
	state["war"]["assault_unlocked"] = true
	state["offers"] = CampaignDirector.generate(state)
	return state


func _offer(state: Dictionary, type: String) -> Dictionary:
	for op: Dictionary in state["offers"]:
		if op["type"] == type:
			return op
	return {}


func _change(report: Dictionary, region: String) -> Dictionary:
	for change: Dictionary in report["changes"]:
		if change["region_id"] == region:
			return change
	return {}


# CAMPAIGN.md §6.1: 0–19, 20–39, 40–59, 60–79, 80–100.
func test_stage_thresholds(infection: int, expected: int, test_parameters := [
		[0, 0], [19, 0], [20, 1], [39, 1], [40, 2], [59, 2], [60, 3], [79, 3], [80, 4], [100, 4]]) -> void:
	assert_int(CampaignRules.stage(infection)).is_equal(expected)


func test_initial_is_valid_and_reproducible() -> void:
	var a := CampaignRules.initial(SEED)
	var b := CampaignRules.initial(SEED)
	assert_bool(CampaignRules.valid(a)).is_true()
	assert_dict(a).is_equal(b)
	assert_int(a["offers"].size()).is_equal(CampaignCatalog.BALANCE["offers"])
	for id: String in CampaignCatalog.REGIONS:
		assert_int(a["regions"][id]["infection"]).is_equal(CampaignCatalog.BALANCE["initial_infection"][id])


func test_advance_does_not_mutate_input() -> void:
	var state := CampaignRules.initial(SEED)
	var before := state.duplicate(true)
	CampaignRules.advance(state, state["offers"][0], "victory")
	CampaignRules.advance(state, state["offers"][1], "defeat", true)
	assert_dict(state).is_equal(before)


func test_victory_lowers_target_infection() -> void:
	var state := CampaignRules.initial(SEED)
	var op := _offer(state, "clearance")
	assert_dict(op).is_not_empty()
	var result := CampaignRules.advance(state, op, "victory")
	var region: String = op["region_id"]
	var after := int(result["world"]["regions"][region]["infection"])
	assert_int(after).is_less(int(state["regions"][region]["infection"]))
	assert_int(_change(result["report"], region)["to"]).is_equal(after)


func test_defeat_raises_target_infection() -> void:
	var state := CampaignRules.initial(SEED)
	var op: Dictionary = state["offers"][0]
	var region: String = op["region_id"]
	var before := int(state["regions"][region]["infection"])
	var result := CampaignRules.advance(state, op, "defeat")
	var expected_min := mini(100, before + int(CampaignCatalog.BALANCE["defeat"]["infection"]))
	assert_int(int(result["world"]["regions"][region]["infection"])).is_greater_equal(expected_min)


# CAMPAIGN.md: удар по улью — заражение −40, соседям −8; Объект-7 открывает путь к Сердцу Улья.
func test_object7_victory_kills_nest_and_opens_heart() -> void:
	# До открытия штурма удар по улью не предлагается.
	assert_dict(_offer(CampaignRules.initial(SEED), "nest")).is_empty()
	var state := _unlocked(SEED)
	assert_bool(CampaignRules.valid(state)).is_true()
	var op := _offer(state, "nest")
	assert_str(op.get("region_id", "")).is_equal("east_europe")
	assert_bool(state["nests"]["hive_heart"]["discovered"]).is_false()
	var result := CampaignRules.advance(state, op, "victory")
	var world: Dictionary = result["world"]
	assert_bool(CampaignRules.valid(world)).is_true()
	assert_bool(world["nests"]["object_7"]["alive"]).is_false()
	assert_bool(world["nests"]["hive_heart"]["discovered"]).is_true()
	var before := int(state["regions"]["east_europe"]["infection"])
	# После прямого эффекта рост подавлен на BALANCE.suppression за ход.
	var limit := before + int(CampaignCatalog.BALANCE["nest"]["infection"]) + int(CampaignCatalog.BALANCE["growth_cap"]) - int(CampaignCatalog.BALANCE["suppression"])
	assert_int(int(world["regions"]["east_europe"]["infection"])).is_less_equal(limit)
	assert_str(result["report"]["events"][0]).contains("Сердцу Улья")


# Подавление снимает до BALANCE.suppression роста за ход, но не уводит рост в минус.
func test_suppression_cuts_growth() -> void:
	var state := CampaignRules.initial(SEED)
	for id: String in CampaignCatalog.REGIONS:
		var free := int(CampaignRules.pressure(state, id)["growth"])
		var held := state.duplicate(true)
		held["regions"][id]["suppressed_turns"] = 2
		var growth := int(CampaignRules.pressure(held, id)["growth"])
		assert_int(growth).is_equal(maxi(0, free - int(CampaignCatalog.BALANCE["suppression"])))


# 40 ходов войны одним и тем же сценарием: мир остаётся валидным, заражение в 0..100, рост в пределах.
func test_long_war_keeps_world_valid() -> void:
	var state := CampaignRules.initial(SEED)
	for turn in 40:
		if state["offers"].is_empty():
			break
		for id: String in CampaignCatalog.REGIONS:
			var growth := int(CampaignRules.pressure(state, id)["growth"])
			assert_int(growth).is_between(0, CampaignCatalog.BALANCE["growth_cap"])
		var op: Dictionary = state["offers"][turn % state["offers"].size()]
		var outcome := "victory" if turn % 3 != 2 else "defeat"
		var next: Dictionary = CampaignRules.advance(state, op, outcome)["world"]
		assert_int(int(next["turn"])).is_equal(int(state["turn"]) + 1)
		assert_bool(CampaignRules.valid(next)).override_failure_message("ход %d невалиден" % turn).is_true()
		for id: String in CampaignCatalog.REGIONS:
			assert_int(int(next["regions"][id]["infection"])).is_between(0, 100)
		state = next


func test_phase_rules() -> void:
	var state := CampaignRules.initial(SEED)
	assert_str(CampaignRules.phase(state)).is_equal("active")
	var lost := state.duplicate(true)
	for i in int(CampaignCatalog.BALANCE["defeat_lost"]) - 1:
		lost["regions"][CampaignCatalog.KEY_REGIONS[i]]["infection"] = 100
	assert_str(CampaignRules.phase(lost)).is_equal("active")
	lost["regions"][CampaignCatalog.KEY_REGIONS[int(CampaignCatalog.BALANCE["defeat_lost"]) - 1]]["infection"] = 100
	assert_str(CampaignRules.phase(lost)).is_equal("defeat")
	var won := state.duplicate(true)
	won["nests"]["hive_heart"]["alive"] = false
	assert_str(CampaignRules.phase(won)).is_equal("victory")


# Значения вне 0..100 и дробные отвергаются, а не маскируются clamp.
func test_valid_rejects_broken_saves(field: String, value: Variant, test_parameters := [
		["infection", 101], ["infection", -1], ["infection", 50.5], ["schema_version", 2], ["seed", -5]]) -> void:
	var state := CampaignRules.initial(SEED)
	if field == "infection":
		state["regions"]["west_europe"]["infection"] = value
	else:
		state[field] = value
	assert_bool(CampaignRules.valid(state)).is_false()


func test_normalized_restores_json_numbers() -> void:
	var data: Dictionary = CampaignRules.normalized({"turn": 3.0, "dna_mul": 2.0, "list": [1.0, 2.5]})
	assert_int(typeof(data["turn"])).is_equal(TYPE_INT)
	assert_int(typeof(data["dna_mul"])).is_equal(TYPE_FLOAT)
	assert_int(typeof(data["list"][0])).is_equal(TYPE_INT)
	assert_float(data["list"][1]).is_equal(2.5)


func test_migrate_v2_to_v3() -> void:
	var old := _unlocked(SEED)
	old["schema_version"] = 2
	old.erase("war")
	var migrated: Dictionary = CampaignRules.migrate(old)
	assert_int(migrated["schema_version"]).is_equal(3)
	assert_bool(CampaignRules.valid(migrated)).is_true()
	assert_dict(migrated["regions"]).is_equal(old["regions"])
	assert_dict(migrated["offers"][0]).is_equal(old["offers"][0])
	# Битое сохранение возвращается как есть, без «починки».
	var broken := old.duplicate(true)
	broken["regions"]["siberia"]["infection"] = 150
	assert_dict(CampaignRules.migrate(broken)).is_equal(broken)
	var current := CampaignRules.initial(SEED)
	assert_dict(CampaignRules.migrate(current)).is_equal(current)


func test_mission_run_id_is_stable() -> void:
	var state := CampaignRules.initial(SEED)
	var op: Dictionary = state["offers"][0]
	var mission := CampaignRules.mission(state, op, 4)
	assert_str(mission["run_id"]).is_equal("c%d-%s-0-%d-4" % [SEED, op["region_id"], op["seed"]])
	assert_dict(CampaignRules.mission(state, op, 4)).is_equal(mission)
