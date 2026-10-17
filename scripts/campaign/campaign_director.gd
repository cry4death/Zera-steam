class_name CampaignDirector
extends RefCounted
## Только локальный RNG: повторная загрузка не меняет предложения.


static func nest_available(state: Dictionary, id: String) -> bool:
	if not CampaignCatalog.NESTS.has(id):
		return false
	var nest: Dictionary = state["nests"][id]
	if not nest["alive"] or not nest["discovered"] or not CampaignCatalog.NESTS[id]["playable"]:
		return false
	if id == "hive_heart":
		var destroyed := 0
		for other: String in state["nests"]:
			if other != id and not state["nests"][other]["alive"]:
				destroyed += 1
		return destroyed >= int(CampaignCatalog.BALANCE["final_required"])
	return true


static func generate(state: Dictionary) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(state["seed"]) ^ int(state["turn"])
	var candidates: Array[String] = []
	for id: String in CampaignCatalog.REGIONS:
		if state["regions"][id]["discovered"]:
			candidates.append(id)
	candidates.sort()
	# Хотя бы стартовый регион известен в любом валидном состоянии.
	if candidates.is_empty():
		candidates.append("east_europe")
	var out: Array[Dictionary] = []
	var safe: String = candidates[rng.randi_range(0, candidates.size() - 1)]
	out.append(_operation(state, safe, "clearance", _threat(int(CampaignCatalog.BALANCE["threat_min"]), int(CampaignCatalog.BALANCE["safe_max"]), rng), 0, rng))
	var standard := _weighted_region(state, candidates, safe, rng)
	out.append(_operation(state, standard, "clearance", int(CampaignCatalog.BALANCE["standard_threat"]), 1, rng))
	# Отдельная карточка улья занимает особую квоту и доступна на каждом ходу.
	if nest_available(state, "object_7"):
		out.append(_operation(state, "east_europe", "nest", int(CampaignCatalog.BALANCE["nest_threat"]), 2, rng))
	else:
		var risky := _weighted_region(state, candidates, standard, rng)
		out.append(_operation(state, risky, "clearance", _threat(int(CampaignCatalog.BALANCE["risky_min"]), int(CampaignCatalog.BALANCE["threat_max"]), rng), 2, rng))
	return out


static func _threat(low: int, high: int, rng: RandomNumberGenerator) -> int:
	var total := 0
	for tier in range(low, high + 1):
		total += int(CampaignCatalog.BALANCE["threat_weights"][tier - 1])
	var roll := rng.randi_range(1, total)
	for tier in range(low, high + 1):
		roll -= int(CampaignCatalog.BALANCE["threat_weights"][tier - 1])
		if roll <= 0:
			return tier
	return low


static func _weighted_region(state: Dictionary, candidates: Array[String], avoid: String, rng: RandomNumberGenerator) -> String:
	var weights: Array[int] = []
	var total := 0
	for id: String in candidates:
		var weight := 1
		if int(state["regions"][id]["infection"]) >= int(CampaignCatalog.BALANCE["stages"][2]):
			weight += int(CampaignCatalog.BALANCE["priority_critical"])
		if CampaignCatalog.REGIONS[id]["asset"] != "":
			weight += int(CampaignCatalog.BALANCE["priority_asset"])
		for nest: String in state["nests"]:
			if state["nests"][nest]["alive"] and CampaignCatalog.REGIONS[id]["neighbors"].has(CampaignCatalog.NESTS[nest]["region_id"]):
				weight += int(CampaignCatalog.BALANCE["priority_nest"])
		if id == avoid and candidates.size() > 1:
			weight = 0
		weights.append(weight)
		total += weight
	var roll := rng.randi_range(1, total)
	for i in candidates.size():
		roll -= weights[i]
		if roll <= 0:
			return candidates[i]
	return candidates[0]


static func _operation(state: Dictionary, region: String, type: String, threat: int, slot: int, rng: RandomNumberGenerator) -> Dictionary:
	var modifiers: Array[String] = []
	var pool: Array = CampaignCatalog.MODIFIERS.duplicate()
	var count := 0 if threat <= 2 else int(CampaignCatalog.BALANCE["max_modifiers"])
	while modifiers.size() < count and not pool.is_empty():
		var index := rng.randi_range(0, pool.size() - 1)
		var modifier: String = pool.pop_at(index)
		var next := modifiers.duplicate()
		next.append(modifier)
		if CampaignCatalog.compatible(next):
			modifiers = next
	var mul: float = CampaignCatalog.BALANCE["dna_mul"][threat - 1]
	var chance: float = CampaignCatalog.BALANCE["crate_chance"][threat - 1]
	if type == "nest":
		mul += float(CampaignCatalog.BALANCE["nest_dna_bonus"])
	if modifiers.has("resource_cache"):
		mul += float(CampaignCatalog.BALANCE["cache_dna_bonus"])
		chance += float(CampaignCatalog.BALANCE["cache_crate_bonus"])
	var name := "%s %s" % [CampaignCatalog.NAMES_FIRST[rng.randi_range(0, CampaignCatalog.NAMES_FIRST.size() - 1)], CampaignCatalog.NAMES_LAST[rng.randi_range(0, CampaignCatalog.NAMES_LAST.size() - 1)]]
	return {"id": "%s-%s-%d-%d" % [type, region, state["turn"], slot], "region_id": region,
		"type": type, "seed": int(rng.randi() & 0x7fffffff), "offered_turn": int(state["turn"]),
		"name": name, "briefing": "Диспетчер: объект подтверждён. Уничтожьте источник заражения." if type == "nest" else "Диспетчер: зачистите периметр. Уничтожьте носителя сигнала.",
		"arena": "quarantine", "objective": "kill_boss", "supports_partial": false,
		"threat": threat, "modifiers": modifiers,
		"reward": {"dna_mul": minf(mul, CampaignCatalog.BALANCE["max_dna_mul"]), "extra_crate_chance": minf(chance, CampaignCatalog.BALANCE["max_crate_chance"])},
		"effects": {"win": CampaignCatalog.BALANCE["nest" if type == "nest" else "victory"].duplicate(), "loss": CampaignCatalog.BALANCE["defeat"].duplicate()}}
