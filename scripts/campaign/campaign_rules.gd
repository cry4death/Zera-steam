class_name CampaignRules
extends RefCounted
## Чистая модель. Входные словари никогда не меняются.


static func initial(seed: int) -> Dictionary:
	var state := {"schema_version": 1, "campaign_id": "earth-%d" % seed, "seed": seed,
		"turn": 0, "phase": "active", "regions": {}, "nests": {}, "offers": [],
		"pending_operation": {}, "last_completed_run_id": "", "last_report": {}, "completed_reports": {}, "recent_events": [], "run_serial": 0}
	for id: String in CampaignCatalog.REGIONS:
		state["regions"][id] = {"infection": int(CampaignCatalog.BALANCE["initial_infection"][id]), "discovered": true,
			"suppressed_turns": 0, "last_changed_turn": 0}
	for id: String in CampaignCatalog.NESTS:
		state["nests"][id] = {"alive": true, "discovered": id == "object_7"}
	state["offers"] = CampaignDirector.generate(state)
	return state


static func stage(infection: int) -> int:
	var result := 0
	for threshold: int in CampaignCatalog.BALANCE["stages"]:
		if infection >= threshold:
			result += 1
	return result


static func pressure(state: Dictionary, id: String) -> Dictionary:
	var region: Dictionary = state["regions"][id]
	var causes: Array[String] = []
	var own := int(CampaignCatalog.BALANCE["self_growth"]) if int(region["infection"]) >= int(CampaignCatalog.BALANCE["stages"][0]) else 0
	var neighbors := 0
	for other: String in CampaignCatalog.REGIONS[id]["neighbors"]:
		if int(state["regions"][other]["infection"]) >= int(CampaignCatalog.BALANCE["stages"][2]):
			neighbors += int(CampaignCatalog.BALANCE["neighbor_pressure"])
	neighbors = mini(neighbors, CampaignCatalog.BALANCE["neighbor_cap"])
	var nest := 0
	for key: String in state["nests"]:
		# Неподтверждённые сигналы пока не участвуют в войне среза.
		if CampaignCatalog.NESTS[key]["playable"] and CampaignCatalog.NESTS[key]["region_id"] == id and state["nests"][key]["alive"]:
			nest += int(CampaignCatalog.BALANCE["nest_pressure"])
	var raw := mini(own + neighbors + nest, CampaignCatalog.BALANCE["growth_cap"])
	var suppression := int(CampaignCatalog.BALANCE["suppression"]) if int(region["suppressed_turns"]) > 0 else 0
	if own > 0:
		causes.append("Локальный рост +%d" % own)
	if neighbors > 0:
		causes.append("Соседние критические зоны +%d" % neighbors)
	if nest > 0:
		causes.append("Действующий улей +%d" % nest)
	if raw < own + neighbors + nest:
		causes.append("Предел роста −%d" % (own + neighbors + nest - raw))
	if suppression > 0:
		causes.append("Подавление −%d (применено %d)" % [suppression, mini(raw, suppression)])
	return {"growth": maxi(0, raw - suppression), "causes": causes}


static func advance(state: Dictionary, operation: Dictionary, outcome: String) -> Dictionary:
	var next := state.duplicate(true)
	var direct_causes := {}
	var target: String = operation["region_id"]
	var effect: Dictionary = CampaignCatalog.BALANCE["nest" if outcome == "victory" and operation["type"] == "nest" else outcome]
	_apply_direct(next, target, int(effect["infection"]), direct_causes, "Операция")
	for id: String in CampaignCatalog.REGIONS[target]["neighbors"]:
		_apply_direct(next, id, int(effect["neighbors"]), direct_causes, "Соседняя операция")
	# N означает N пересчётов, включая текущий. После роста остаётся N−1.
	# Победа с N=2 защищает ходы 1 и 2; на ходу 3 защиты уже нет.
	next["regions"][target]["suppressed_turns"] = maxi(int(next["regions"][target]["suppressed_turns"]), int(effect["suppression"]))
	var events: Array[String] = []
	if operation["type"] == "nest" and outcome == "victory":
		next["nests"]["object_7"]["alive"] = false
		events.append("Сигнал улья Объект-7 пропал. Объект уничтожен.")
	var snapshot := next.duplicate(true)
	next["turn"] = int(state["turn"]) + 1
	var changes: Array[Dictionary] = []
	var stage_events: Array[String] = []
	var ordinary_events: Array[String] = []
	var critical := 0
	var nests_alive := 0
	for id: String in CampaignCatalog.REGIONS:
		var p := pressure(snapshot, id)
		var region: Dictionary = next["regions"][id]
		var before := int(state["regions"][id]["infection"])
		var prior_growth := int(snapshot["regions"][id]["infection"])
		region["infection"] = clampi(prior_growth + int(p["growth"]), CampaignCatalog.BALANCE["infection_min"], CampaignCatalog.BALANCE["infection_max"])
		region["suppressed_turns"] = maxi(0, int(region["suppressed_turns"]) - 1)
		var after := int(region["infection"])
		if stage(after) >= 3:
			critical += 1
		var causes: Array = direct_causes.get(id, []).duplicate()
		causes.append_array(p["causes"])
		if after != prior_growth + int(p["growth"]):
			causes.append("Предел заражения −%d" % (prior_growth + int(p["growth"]) - after))
		if before != after or not causes.is_empty():
			if before != after:
				region["last_changed_turn"] = next["turn"]
			changes.append({"region_id": id, "name": CampaignCatalog.REGIONS[id]["name"], "from": before, "to": after,
				"stage_from": stage(before), "stage_to": stage(after), "causes": causes})
			var message := "%s: %d → %d" % [CampaignCatalog.REGIONS[id]["name"], before, after]
			if stage(before) != stage(after):
				stage_events.append(message + " · " + CampaignCatalog.STAGES[stage(after)])
			elif before != after:
				ordinary_events.append(message)
	for id: String in next["nests"]:
		if next["nests"][id]["alive"] and CampaignCatalog.NESTS[id]["playable"]:
			nests_alive += 1
	events.append_array(stage_events)
	# Новые особые миссии пока не открываются: остальные боссы ещё не реализованы.
	events.append_array(ordinary_events)
	if events.size() > 3:
		events.resize(3)
	next["offers"] = CampaignDirector.generate(next)
	next["recent_events"] = events.duplicate()
	return {"world": next, "report": {"changes": changes, "events": events, "nests_alive": nests_alive, "critical": critical}}


static func _apply_direct(state: Dictionary, id: String, amount: int, causes: Dictionary, label: String) -> void:
	if amount == 0:
		return
	var before := int(state["regions"][id]["infection"])
	state["regions"][id]["infection"] = clampi(before + amount, CampaignCatalog.BALANCE["infection_min"], CampaignCatalog.BALANCE["infection_max"])
	causes[id] = ["%s %+d (применено %+d)" % [label, amount, int(state["regions"][id]["infection"]) - before]]


static func integer(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and float(value) >= low and float(value) <= high


## JSON возвращает числа как float; в памяти счётчики остаются int.
static func normalized(value: Variant, key: String = "") -> Variant:
	if value is Dictionary:
		var result := {}
		for field: Variant in value:
			result[field] = normalized(value[field], str(field))
		return result
	if value is Array:
		var result: Array = []
		for item: Variant in value:
			result.append(normalized(item))
		return result
	if value is float or value is int:
		if key in ["dna_mul", "extra_crate_chance", "dna_mult", "time", "blood_liters"]:
			return float(value)
		if integer(value, -2147483647, 2147483647):
			return int(value)
	return value


## Значения вне 0..100 (включая дробные) отвергаются, а не маскируются clamp.
## Неизвестные регионы, шаблоны, возрождение улья через pending/предложения отвергаются.
static func valid(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var d: Dictionary = value
	if d.get("schema_version") != 1 or not integer(d.get("seed"), 0, CampaignCatalog.BALANCE["max_seed"]) or not integer(d.get("turn"), 0, CampaignCatalog.BALANCE["max_turn"]):
		return false
	if d.get("campaign_id") != "earth-%d" % int(d["seed"]) or d.get("phase") != "active" or not integer(d.get("run_serial"), 0, CampaignCatalog.BALANCE["max_seed"]):
		return false
	if not d.get("regions") is Dictionary or d["regions"].size() != CampaignCatalog.REGIONS.size() or not d.get("nests") is Dictionary or d["nests"].size() != CampaignCatalog.NESTS.size():
		return false
	for id: String in CampaignCatalog.REGIONS:
		var r: Variant = d["regions"].get(id)
		if not r is Dictionary:
			return false
		if not integer(r.get("infection"), 0, 100) or not r.get("discovered") is bool or not integer(r.get("suppressed_turns"), 0, 3) or not integer(r.get("last_changed_turn"), 0, int(d["turn"])):
			return false
	if not d["regions"]["east_europe"]["discovered"]:
		return false
	for id: String in CampaignCatalog.NESTS:
		var n: Variant = d["nests"].get(id)
		if not n is Dictionary or not n.get("alive") is bool or not n.get("discovered") is bool:
			return false
	if not d["nests"]["object_7"]["discovered"]:
		return false
	if not d.get("offers") is Array or d["offers"].size() != int(CampaignCatalog.BALANCE["offers"]):
		return false
	var ids: Array[String] = []
	var easy := false
	var nest_offered := false
	for op: Variant in d["offers"]:
		if not valid_operation(op, d) or ids.has(op["id"]):
			return false
		ids.append(op["id"])
		easy = easy or int(op["threat"]) <= 2
		nest_offered = nest_offered or op["type"] == "nest"
	if CampaignDirector.nest_available(d, "object_7") and not nest_offered:
		return false
	if not easy or not d.get("pending_operation") is Dictionary or not d.get("last_report") is Dictionary or not d.get("recent_events") is Array or not d.get("last_completed_run_id") is String:
		return false
	if not d.get("completed_reports") is Dictionary:
		return false
	for run_id: Variant in d["completed_reports"]:
		if not run_id is String or run_id.is_empty() or not d["completed_reports"][run_id] is Dictionary or not valid_report(d["completed_reports"][run_id], run_id):
			return false
	var pending: Dictionary = d["pending_operation"]
	if not pending.is_empty():
		if not pending.get("run_id") is String or pending["run_id"].is_empty() or d["completed_reports"].has(pending["run_id"]) or not pending.get("operation_id") is String:
			return false
		var found := false
		for op: Dictionary in d["offers"]:
			if op["id"] == pending["operation_id"]:
				found = pending == mission(d, op, int(d["run_serial"]))
		if not found:
			return false
	if not d["last_completed_run_id"].is_empty():
		var report: Dictionary = d["last_report"]
		if not valid_report(report, d["last_completed_run_id"]) or d["completed_reports"].get(d["last_completed_run_id"]) != report:
			return false
	elif not d["last_report"].is_empty():
		return false
	return true


static func valid_report(report: Dictionary, run_id: String) -> bool:
	if report.get("run_id") != run_id or not report.get("stats") is Dictionary or not report.get("changes") is Array or not report.get("events") is Array:
		return false
	if report["stats"].get("run_id") != run_id or report["events"].size() > 3 or not integer(report.get("critical"), 0, 8) or not integer(report.get("nests_alive"), 0, 5):
		return false
	for key: String in ["dna_total", "crates", "military_crates"]:
		if not integer(report["stats"].get(key), 0, int(CampaignCatalog.BALANCE["reward_limit"]) * 2):
			return false
	for event: Variant in report["events"]:
		if not event is String:
			return false
	for change: Variant in report["changes"]:
		if not change is Dictionary or not CampaignCatalog.REGIONS.has(change.get("region_id")) or not change.get("name") is String or not change.get("causes") is Array:
			return false
		for key: String in ["from", "to", "stage_from", "stage_to"]:
			if not integer(change.get(key), 0, 4 if key.begins_with("stage") else 100):
				return false
		for cause: Variant in change["causes"]:
			if not cause is String:
				return false
	return true


static func valid_operation(value: Variant, state: Dictionary) -> bool:
	if not value is Dictionary:
		return false
	var op: Dictionary = value
	if not op.get("id") is String or op["id"].is_empty() or not CampaignCatalog.REGIONS.has(op.get("region_id")) or op.get("type") not in ["clearance", "nest"]:
		return false
	if not state["regions"][op["region_id"]]["discovered"] or not integer(op.get("seed"), 0, CampaignCatalog.BALANCE["max_seed"]) or not integer(op.get("offered_turn"), int(state["turn"]), int(state["turn"])):
		return false
	if op["type"] == "nest" and (op["region_id"] != "east_europe" or not CampaignDirector.nest_available(state, "object_7")):
		return false
	if not integer(op.get("threat"), 1, 5) or not op.get("modifiers") is Array or op["modifiers"].size() > int(CampaignCatalog.BALANCE["max_modifiers"]):
		return false
	var used: Array = []
	for mod: Variant in op["modifiers"]:
		if not CampaignCatalog.MODIFIERS.has(mod) or used.has(mod):
			return false
		used.append(mod)
	if not CampaignCatalog.compatible(used) or not op.get("reward") is Dictionary:
		return false
	for key: String in ["name", "briefing", "arena", "objective"]:
		if not op.get(key) is String or op[key].is_empty():
			return false
	for key: String in ["dna_mul", "extra_crate_chance"]:
		var v: Variant = op["reward"].get(key)
		var maximum := float(CampaignCatalog.BALANCE["max_dna_mul"] if key == "dna_mul" else CampaignCatalog.BALANCE["max_crate_chance"])
		var minimum := 1.0 if key == "dna_mul" else 0.0
		if not (v is float or v is int) or not is_finite(float(v)) or float(v) < minimum or float(v) > maximum:
			return false
	return op.get("supports_partial") == false and op.get("effects") is Dictionary and normalized(op["effects"].get("win")) == CampaignCatalog.BALANCE["nest" if op["type"] == "nest" else "victory"] and normalized(op["effects"].get("loss")) == CampaignCatalog.BALANCE["defeat"]


static func mission(state: Dictionary, op: Dictionary, serial: int) -> Dictionary:
	var config := op.duplicate(true)
	config["operation_id"] = op["id"]
	config["run_id"] = "c%d-%s-%d-%d-%d" % [state["seed"], op["region_id"], state["turn"], op["seed"], serial]
	config["region_name"] = CampaignCatalog.REGIONS[op["region_id"]]["name"]
	config["boss"] = "object_7"
	return config
