class_name CampaignDirector
extends RefCounted
## Только локальный RNG: повторная загрузка не меняет предложения.


static func nest_available(state: Dictionary, id: String) -> bool:
	if state.get("phase") == "defeat" or not CampaignCatalog.NESTS.has(id):
		return false
	# Путь, вскрытый Объектом-7, не закрывается заражением и не требует Генерала.
	if id == "hive_heart":
		return state.get("phase") == "active" and not state["nests"]["object_7"]["alive"] and state["nests"][id]["alive"]
	if int(state["regions"][CampaignCatalog.NESTS[id]["region_id"]]["infection"]) >= 100:
		return false
	var nest: Dictionary = state["nests"][id]
	if not nest["alive"] or not nest["discovered"] or not CampaignCatalog.NESTS[id]["playable"]:
		return false
	if id == "object_7" and not state["war"]["assault_unlocked"]:
		return false
	if id in ["mother", "meat_mountain", "general"] and int(state["turn"]) < 3:
		return false
	return true


static func generate(state: Dictionary) -> Array[Dictionary]:
	if state.get("phase") == "defeat":
		return []
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
	for id: String in candidates:
		if int(state["regions"][id]["infection"]) < int(state["regions"][safe]["infection"]):
			safe = id
	# Первые безопасные вылазки строят сеть, а не фармят одну чистую точку.
	if not state["war"]["assault_unlocked"] and state["war"]["outposts"].size() < int(CampaignCatalog.BALANCE["assault_outposts"]):
		var unfortified := ""
		for id: String in candidates:
			if not state["war"]["outposts"].has(id) and (unfortified.is_empty() or int(state["regions"][id]["infection"]) < int(state["regions"][unfortified]["infection"])):
				unfortified = id
		if not unfortified.is_empty():
			safe = unfortified
	out.append(_operation(state, safe, "clearance", _threat(int(CampaignCatalog.BALANCE["threat_min"]), int(CampaignCatalog.BALANCE["safe_max"]), rng), 0, rng))
	var standard := _weighted_region(state, candidates, safe, rng)
	var announced: Dictionary = state["war"]["front"]
	if state["war"]["assault_unlocked"] and not announced.is_empty() and not announced["stopped"]:
		standard = announced["target"]
	if state["war"]["samples"].size() < int(CampaignCatalog.BALANCE["assault_samples"]) and state["war"]["samples"].has(standard):
		for id: String in candidates:
			if id != safe and not state["war"]["samples"].has(id):
				standard = id
				break
	# Потерянный регион всегда можно вернуть на текущем ходу.
	for id: String in candidates:
		if int(state["regions"][id]["infection"]) >= 100:
			standard = id
			break
	out.append(_operation(state, standard, "extract", int(CampaignCatalog.BALANCE["standard_threat"]), 1, rng))
	# Последняя квота: объявленная угроза или новый форпост, затем финальный штурм.
	if nest_available(state, "hive_heart"):
		out.append(_operation(state, "south_asia", "nest", 5, 2, rng))
	elif nest_available(state, "object_7"):
		out.append(_operation(state, "east_europe", "nest", int(CampaignCatalog.BALANCE["nest_threat"]), 2, rng))
	else:
		var risky := _weighted_region(state, candidates, standard, rng)
		var strike: Dictionary = state["war"]["front"]
		if not strike.is_empty() and not strike["stopped"]:
			risky = strike["target"]
		elif not state["war"]["assault_unlocked"]:
			for id: String in candidates:
				if id != safe and not state["war"]["outposts"].has(id):
					risky = id
					break
		var optional := ""
		# Необязательный улей не вытесняет защиту объявленного фронта.
		if strike.is_empty() or strike["stopped"]:
			for id: String in ["mother", "meat_mountain", "general"]:
				if nest_available(state, id):
					optional = id
					break
		if not optional.is_empty():
			out.append(_operation(state, CampaignCatalog.NESTS[optional]["region_id"], "nest", int(CampaignCatalog.BALANCE["nest_threat"]), 2, rng))
		else:
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
	var finale := type == "nest" and region == "south_asia" and nest_available(state, "hive_heart")
	if int(state["regions"][region]["infection"]) >= 100 and not finale:
		type = "reclaim"
		threat = 5
	var stage_profile: Dictionary = CampaignCatalog.STAGE_COMBAT[CampaignRules.stage(int(state["regions"][region]["infection"]))]
	threat = maxi(threat, int(stage_profile["threat"]))
	var modifiers: Array[String] = []
	modifiers.assign(CampaignCatalog.region_modifiers(state, region, stage_profile["modifiers"]))
	var pool: Array = CampaignCatalog.region_modifiers(state, region, CampaignCatalog.MODIFIERS)
	if type != "nest":
		pool.erase("hardened_boss")
	for id: String in modifiers:
		pool.erase(id)
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
	if type == "extract":
		chance += float(CampaignCatalog.BALANCE["extract_crate_bonus"])
	if type == "reclaim":
		mul += float(CampaignCatalog.BALANCE["reclaim_dna_bonus"])
		chance += float(CampaignCatalog.BALANCE["reclaim_crate_bonus"])
	if type == "nest":
		mul += float(CampaignCatalog.BALANCE["nest_dna_bonus"])
	if modifiers.has("resource_cache"):
		mul += float(CampaignCatalog.BALANCE["cache_dna_bonus"])
		chance += float(CampaignCatalog.BALANCE["cache_crate_bonus"])
	# Два пустых броска прежнего генератора имён: без них сдвинется seed операции.
	rng.randi_range(0, CampaignCatalog.LEGACY_NAME_DRAWS - 1)
	rng.randi_range(0, CampaignCatalog.LEGACY_NAME_DRAWS - 1)
	var name: String = CampaignCatalog.OP_NAMES[type]
	var nest_id := CampaignCatalog.nest_in(region)
	var briefing := "Диспетчер: уничтожьте Объект-7. Это ослабит заражение в регионе и у соседей."
	if type == "nest" and nest_id in ["mother", "meat_mountain", "general"]:
		name = "Ликвидация: " + str(CampaignCatalog.NESTS[nest_id]["name"])
		briefing = "Матка. Отстреливайте родовые мешки, уходите с трещин на земле." if nest_id == "mother" else "Мясная гора. Уходите поперёк навала, не заходите в гниль. Отпавшие тела оживают."
		if nest_id == "general":
			briefing = "Генерал. Обходите щит, пробивайте экзоброню. Уходите с миномётных отметок и прерывайте строй охраны."
	if finale:
		name = "Сердце Улья"
		briefing = "Диспетчер: проход к центральному улью открыт. Уничтожьте Сердце — война закончится. Группа сможет повторить штурм при неудаче."
	return {"id": "%s-%s-%d-%d" % [type, region, state["turn"], slot], "region_id": region,
		"type": type, "seed": int(rng.randi() & 0x7fffffff), "offered_turn": int(state["turn"]),
		"name": name, "briefing": briefing if type == "nest" else ("Диспетчер: заберите контейнер и удержите площадку эвакуации. Борт на 5:00." if type == "extract" else "Диспетчер: узел заражения на 10:00. Уничтожьте его."),
		"arena": "quarantine", "objective": CampaignCatalog.objective(type), "supports_partial": false,
		"threat": threat, "modifiers": modifiers,
		"reward": {"dna_mul": minf(mul, CampaignCatalog.BALANCE["max_dna_mul"]), "extra_crate_chance": minf(chance, CampaignCatalog.BALANCE["max_crate_chance"])},
		"effects": {"win": CampaignCatalog.BALANCE[CampaignCatalog.effect_key(type)].duplicate(), "loss": CampaignCatalog.BALANCE["defeat"].duplicate()}}
