class_name CampaignWar
extends RefCounted
## Рубежи войны и объявленный удар. Время идёт только после операции.


static func initial(state: Dictionary, legacy: bool = false) -> Dictionary:
	return {"outposts": [], "samples": [], "assault_unlocked": legacy, "front": front(state), "history": []}


static func front(state: Dictionary) -> Dictionary:
	if not state["nests"]["object_7"]["alive"] or state["phase"] in ["victory", "free", "defeat"]:
		return {}
	var source := "east_europe"
	for id: String in CampaignCatalog.REGIONS:
		if int(state["regions"][id]["infection"]) > int(state["regions"][source]["infection"]):
			source = id
	var neighbors: Array = CampaignCatalog.REGIONS[source]["neighbors"]
	var cycle := int(state["turn"]) / int(CampaignCatalog.BALANCE["front_period"])
	var target: String = neighbors[(int(state["seed"]) + cycle) % neighbors.size()]
	return {"source": source, "target": target, "due_turn": (cycle + 1) * int(CampaignCatalog.BALANCE["front_period"]), "stopped": false}


static func before_growth(state: Dictionary, op: Dictionary, outcome: String, causes: Dictionary, events: Array[String]) -> void:
	var war: Dictionary = state["war"]
	var id: String = op["region_id"]
	if outcome == "victory":
		if op["type"] in ["clearance", "reclaim"] and not war["outposts"].has(id):
			war["outposts"].append(id)
			events.append("Форпост: " + CampaignCatalog.REGIONS[id]["name"])
		if op["type"] == "extract" and not war["samples"].has(id):
			war["samples"].append(id)
			events.append("Образец: %d / %d" % [war["samples"].size(), int(CampaignCatalog.BALANCE["assault_samples"])])
	var strike: Dictionary = war["front"]
	if strike.is_empty():
		return
	if not state["nests"]["object_7"]["alive"]:
		war["front"] = {}
		return
	if outcome == "victory" and id == strike["target"] and not strike["stopped"]:
		strike["stopped"] = true
		events.append("Удар сорван: " + CampaignCatalog.REGIONS[id]["name"])
	if int(state["turn"]) + 1 == int(strike["due_turn"]) and not strike["stopped"]:
		var target: String = strike["target"]
		var before := int(state["regions"][target]["infection"])
		var after := mini(100, before + int(CampaignCatalog.BALANCE["front_infection"]))
		state["regions"][target]["infection"] = after
		if not causes.has(target):
			causes[target] = []
		causes[target].append("Наступление: +%d" % (after - before))
		events.append("Удар: %s +%d" % [CampaignCatalog.REGIONS[target]["name"], after - before])


static func after_growth(state: Dictionary, op: Dictionary, outcome: String, events: Array[String], before: float) -> void:
	var war: Dictionary = state["war"]
	for id: String in war["outposts"].duplicate():
		if int(state["regions"][id]["infection"]) >= 80:
			war["outposts"].erase(id)
			events.push_front("Форпост потерян: " + CampaignCatalog.REGIONS[id]["name"])
	if not war["assault_unlocked"] and int(state["turn"]) >= int(CampaignCatalog.BALANCE["assault_turn"]) and war["outposts"].size() >= int(CampaignCatalog.BALANCE["assault_outposts"]) and war["samples"].size() >= int(CampaignCatalog.BALANCE["assault_samples"]):
		war["assault_unlocked"] = true
		events.push_front("Объект-7 найден. Штурм доступен.")
	var strike: Dictionary = war["front"]
	if not strike.is_empty() and int(state["turn"]) >= int(strike["due_turn"]):
		war["front"] = front(state)
	war["history"].push_front({"turn": state["turn"], "region_id": op["region_id"], "type": op["type"], "outcome": outcome, "delta": roundi(CampaignRules.average(state) - before)})
	war["history"].resize(mini(6, war["history"].size()))


static func valid(value: Variant, turn: int) -> bool:
	if not value is Dictionary or not value.get("assault_unlocked") is bool:
		return false
	for key: String in ["outposts", "samples"]:
		if not value.get(key) is Array or value[key].size() > 8:
			return false
		var seen: Array = []
		for id: Variant in value[key]:
			if not id is String or not CampaignCatalog.REGIONS.has(id) or seen.has(id):
				return false
			seen.append(id)
	if not value.get("front") is Dictionary or not value.get("history") is Array or value["history"].size() > 6:
		return false
	var strike: Dictionary = value["front"]
	if not strike.is_empty():
		if not CampaignCatalog.REGIONS.has(strike.get("source")) or not CampaignCatalog.REGIONS.has(strike.get("target")):
			return false
		if not CampaignCatalog.REGIONS[strike["source"]]["neighbors"].has(strike["target"]) or not strike.get("stopped") is bool or not CampaignRules.integer(strike.get("due_turn"), turn + 1, turn + int(CampaignCatalog.BALANCE["front_period"])):
			return false
	for item: Variant in value["history"]:
		if not item is Dictionary or not CampaignCatalog.REGIONS.has(item.get("region_id")) or item.get("type") not in CampaignCatalog.OP_NAMES or item.get("outcome") not in ["victory", "defeat", "partial"]:
			return false
		if not CampaignRules.integer(item.get("turn"), 1, turn) or not CampaignRules.integer(item.get("delta"), -100, 100):
			return false
	return true
