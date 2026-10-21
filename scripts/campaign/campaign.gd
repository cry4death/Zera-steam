class_name Campaign
extends RefCounted
## Фасад: единственная точка запуска и завершения операции.


static func enabled(args: PackedStringArray = OS.get_cmdline_user_args()) -> bool:
	var filtered := PackedStringArray()
	for arg: String in args:
		if args.has("--boss-test") and arg == "--fresh-save":
			continue
		if arg.begins_with("--c6-test") or arg == "--c6-capture" or arg == "--globe-test" or arg == "--campaign-test" or arg == "--boss-test" or arg.begins_with("--campaign-op="):
			continue
		filtered.append(arg)
	return not Meta.is_test_run(filtered)


static func world() -> Dictionary:
	return Meta.campaign.duplicate(true)


static func offers() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for op: Dictionary in Meta.campaign["offers"]:
		result.append(op.duplicate(true))
	return result


static func region_info(id: String) -> Dictionary:
	if not CampaignCatalog.REGIONS.has(id):
		return {}
	var info: Dictionary = CampaignCatalog.REGIONS[id].duplicate(true)
	info.merge(Meta.campaign["regions"][id], true)
	info["stage"] = CampaignRules.stage(int(info["infection"]))
	info["stage_name"] = CampaignCatalog.STAGES[info["stage"]]
	info["danger_reasons"] = CampaignRules.pressure(Meta.campaign, id)["causes"]
	info["nests"] = []
	for nest: String in CampaignCatalog.NESTS:
		if CampaignCatalog.NESTS[nest]["region_id"] == id:
			var item: Dictionary = CampaignCatalog.NESTS[nest].duplicate(true)
			item.merge(Meta.campaign["nests"][nest], true)
			item["id"] = nest
			item["status"] = "Объект подтверждён" if item["playable"] else "Сигнал не подтверждён"
			info["nests"].append(item)
	return info


static func start_operation(op_id: String) -> Dictionary:
	if not enabled() or Meta.campaign["phase"] in ["defeat", "victory"] or not Meta.campaign["pending_operation"].is_empty():
		return {}
	if int(Meta.campaign["turn"]) >= int(CampaignCatalog.BALANCE["max_turn"]) or int(Meta.campaign["run_serial"]) >= int(CampaignCatalog.BALANCE["max_seed"]):
		return {}
	for op: Dictionary in offers():
		if op["id"] != op_id:
			continue
		var previous := Meta.campaign.duplicate(true)
		Meta.campaign["run_serial"] = int(Meta.campaign["run_serial"]) + 1
		var config := CampaignRules.mission(Meta.campaign, op, int(Meta.campaign["run_serial"]))
		Meta.campaign["pending_operation"] = config
		Meta.save() # До смены сцены; при ошибке запись не считается запуском.
		if not Meta.last_save_ok:
			Meta.campaign = previous
			return {}
		return config.duplicate(true)
	return {}


static func pending() -> Dictionary:
	return Meta.campaign.get("pending_operation", {}).duplicate(true) if enabled() else {}


static func complete_operation(stats: Dictionary) -> Dictionary:
	if not enabled():
		return {}
	var run_id: String = str(stats.get("run_id", ""))
	if not run_id.is_empty() and Meta.campaign["completed_reports"].has(run_id):
		return Meta.campaign["completed_reports"][run_id].duplicate(true)
	var config := pending()
	if config.is_empty() or run_id != config["run_id"]:
		return {}
	for key: String in ["operation_id", "region_id", "type"]:
		if stats.has(key) and stats[key] != config[key]:
			return {}
	var outcome: String = str(stats.get("outcome", ""))
	if outcome not in ["victory", "defeat", "partial"] or (outcome == "partial" and not config["supports_partial"]):
		return {}
	if stats.has("victory") and (not stats["victory"] is bool or stats["victory"] != (outcome == "victory")):
		return {}
	for key: String in ["dna_total", "crates", "military_crates"]:
		if not CampaignRules.integer(stats.get(key), 0, CampaignCatalog.BALANCE["reward_limit"]):
			return {}
	var rewarded := stats.duplicate(true)
	if outcome == "victory":
		var before := int(stats["dna_total"])
		rewarded["dna_total"] = floori(before * float(config["reward"]["dna_mul"]))
		rewarded["dna_mult"] = float(stats.get("dna_mult", 1.0)) * float(config["reward"]["dna_mul"])
		var reward_rng := RandomNumberGenerator.new()
		reward_rng.seed = int(config["seed"])
		if reward_rng.randf() < float(config["reward"]["extra_crate_chance"]):
			rewarded["crates"] = int(rewarded["crates"]) + 1
	var result := CampaignRules.advance(Meta.campaign, config, outcome)
	var report: Dictionary = result["report"]
	report["run_id"] = run_id
	report["stats"] = rewarded
	report["save_error"] = ""
	var next: Dictionary = result["world"]
	next["pending_operation"] = {}
	next["last_completed_run_id"] = run_id
	next["last_report"] = report.duplicate(true)
	next["completed_reports"][run_id] = report.duplicate(true)
	# Начисление без записи; мир и награды сохраняются ровно одним снимком.
	Meta.apply_run(rewarded)
	Meta.campaign = next
	Meta.save()
	if not Meta.last_save_ok:
		report["save_error"] = Meta.last_error
		Meta.campaign["last_report"] = report.duplicate(true)
		Meta.campaign["completed_reports"][run_id] = report.duplicate(true)
	# Ошибка записи видна через Meta.last_save_ok/last_error, без ложного успеха.
	# В памяти commit остаётся идемпотентным; повторить запись можно через Meta.save().
	return report.duplicate(true)


static func abandon_pending() -> String:
	if Meta.campaign.get("pending_operation", {}).is_empty():
		return ""
	Meta.campaign["pending_operation"] = {}
	Meta.save()
	var message := "Связь с группой потеряна — операция не засчитана"
	print("Campaign: " + message)
	return message


static func new_campaign(seed: int) -> void:
	Meta.campaign = CampaignRules.initial(clampi(seed, 0, CampaignCatalog.BALANCE["max_seed"]))
	Meta.save()


static func last_report() -> Dictionary:
	return Meta.campaign.get("last_report", {}).duplicate(true)


static func continue_campaign() -> void:
	if Meta.campaign["phase"] == "victory":
		Meta.campaign["phase"] = "free"
		Meta.save()
