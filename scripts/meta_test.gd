class_name MetaTest
extends RefCounted
## Проверка меты и моделей стволов: godot --headless --path . -- --meta-test (запускает game.gd).
## Печатает строки METATEST …, в конце «METATEST ok=true|false». Настоящее сохранение не трогает:
## файловые проверки идут через user://test_save.json, Meta после теста возвращается в прежнее состояние.

const TEST_FILE := "user://test_save.json"
const DT := 1.0 / 60.0

var _g: Node2D
var _weapons: Weapons
var _horde: Horde
var _player: Player
var _failed := 0
var _checks := 0
var _frame := 0
var _shot_frames: Array[int] = []


static func run(game: Node2D) -> bool:
	var t := MetaTest.new()
	return await t._run(game)


func _run(game: Node2D) -> bool:
	_g = game
	_weapons = game.weapons
	_horde = game.horde
	_player = game.player
	_player.god_mode = true
	_weapons.shot_fired.connect(func(_b: int) -> void: _shot_frames.append(_frame))
	var saved := Meta.to_dict()
	var saved_persist := Meta.persist
	var saved_path := Meta.save_path
	Meta.persist = false
	Meta.rng.seed = 20261017
	_test_save_load()
	_test_class_level()
	_test_tree()
	_test_workshop()
	_test_crates()
	_test_favorites()
	_test_run_bonuses_stats()
	await _test_models_table()
	await _test_player_bonuses()
	await _test_last_round()
	await _test_sustained()
	await _test_trait_burst3()
	await _test_trait_slamfire()
	await _test_trait_kill_charge()
	await _test_trait_sticky()
	await _test_trait_hicap()
	await _test_trait_fan()
	await _test_trait_steady()
	await _test_trait_lever()
	_test_results_screen()
	# вернуть мету как была
	Meta.persist = saved_persist
	Meta.save_path = saved_path
	Meta.reset()
	Meta.from_dict(saved)
	print("METATEST checks=%d failed=%d" % [_checks, _failed])
	print("METATEST ok=%s" % str(_failed == 0).to_lower())
	return _failed == 0


func _check(name: String, cond: bool, detail := "") -> void:
	_checks += 1
	if not cond:
		_failed += 1
		print("METATEST FAIL %s %s" % [name, detail])


func _near(a: float, b: float, eps := 0.001) -> bool:
	return absf(a - b) <= eps


# --- сохранение ------------------------------------------------------------------------------

func _remove_test_files() -> void:
	var dir := DirAccess.open("user://")
	for f in dir.get_files():
		if f.begins_with("test_save.json"):
			dir.remove(f)


func _write_text(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _bad_copies() -> int:
	var n := 0
	for f in DirAccess.open("user://").get_files():
		if f.begins_with("test_save.json.bad-"):
			n += 1
	return n


func _test_save_load() -> void:
	_remove_test_files()
	Meta.save_path = TEST_FILE
	Meta.persist = true
	# нет файла: чистое состояние, без падения
	Meta.dna = 999
	_check("save.missing_file", not Meta.load_save() and Meta.dna == 0 and Meta.owned.size() == 8)
	# запись и чтение: все поля
	Meta.reset()
	Meta.dna = 123
	Meta.dna_earned = 500
	Meta.tree = {"fire_1": true, "fire_2": true}
	Meta.owned.append("m4")
	Meta.owned.append("hive")
	Meta.workshop = {"ak_s": {"damage": 3, "reload": 5}, "hive": {"mag": 2}}
	Meta.favorite = {WeaponDefs.Base.RIFLE: "m4"}
	Meta.crates = 3
	Meta.military_crates = 1
	Meta.runs = 2
	Meta.save()
	_check("save.file_written", FileAccess.file_exists(TEST_FILE) and not FileAccess.file_exists(TEST_FILE + ".tmp"), "tmp-файл остался или файла нет")
	Meta.reset()
	_check("save.load_ok", Meta.load_save())
	_check("save.fields", Meta.dna == 123 and Meta.dna_earned == 500 and Meta.crates == 3 and Meta.military_crates == 1 and Meta.runs == 2)
	_check("save.tree_workshop", Meta.tree.size() == 2 and Meta.workshop_level("ak_s", "damage") == 3 and Meta.workshop_level("hive", "mag") == 2)
	_check("save.owned_favorite", Meta.owned.has("m4") and Meta.owned.has("hive") and Meta.owned.has("ak_s") and Meta.model_for(WeaponDefs.Base.RIFLE) == "m4")
	# битый файл: резервная копия, чистое состояние, файл снова валиден
	_write_text(TEST_FILE, "{ это не json ]]")
	_check("save.corrupt_detected", not Meta.load_save() and Meta.dna == 0 and Meta.last_error != "")
	_check("save.corrupt_backup", _bad_copies() == 1, "копий: %d" % _bad_copies())
	_check("save.corrupt_rewritten", Meta.load_save() and Meta.dna == 0)
	# другая версия схемы и неверные типы — то же самое
	_write_text(TEST_FILE, JSON.stringify({"version": 0, "dna": 5}))
	_check("save.old_version", not Meta.load_save() and Meta.dna == 0)
	_write_text(TEST_FILE, JSON.stringify({"version": Meta.SAVE_VERSION, "dna": "много", "dna_earned": 1, "crates": 0, "military_crates": 0, "runs": 0,
		"tree": {}, "workshop": {}, "owned": [], "favorite": {}}))
	_check("save.wrong_types", not Meta.load_save() and Meta.dna == 0)
	_write_text(TEST_FILE, "[1, 2, 3]")
	_check("save.not_object", not Meta.load_save() and Meta.dna == 0)
	# лишнее и испорченное внутри годного файла отбрасывается
	_write_text(TEST_FILE, JSON.stringify({"version": Meta.SAVE_VERSION, "dna": 10, "dna_earned": 10, "crates": 0, "military_crates": 0, "runs": 1,
		"tree": {"fire_3": true, "nope": true}, "workshop": {"ak_s": {"damage": 99, "bogus": 1}, "zzz": {}}, "owned": ["m4", "zzz"],
		"favorite": {"0": "m4", "1": "m4"}}))
	var clean := Meta.load_save()
	_check("save.sanitize", clean and not Meta.tree.has("fire_3") and not Meta.tree.has("nope") and Meta.workshop_level("ak_s", "damage") == 5
		and not Meta.workshop.has("zzz") and Meta.owned.has("m4") and not Meta.owned.has("zzz") and Meta.model_for(WeaponDefs.Base.RIFLE) == "m4"
		and not Meta.favorite.has(1))
	_remove_test_files()
	Meta.persist = false
	Meta.reset()
	print("METATEST save: запись/чтение/битый/старый/типы ок" if _failed == 0 else "METATEST save: есть ошибки")


# --- уровень класса, дерево -----------------------------------------------------------------

func _test_class_level() -> void:
	Meta.reset()
	var table := {2: 80, 3: 226, 4: 416, 5: 640, 6: 894, 8: 1482, 10: 2160}
	var line := ""
	for n: int in table:
		var need: int = table[n]
		_check("level.dna_for_%d" % n, Meta.dna_for_level(n) == need, "%d != %d" % [Meta.dna_for_level(n), need])
		Meta.dna_earned = need - 1
		var below := Meta.class_level()
		Meta.dna_earned = need
		_check("level.threshold_%d" % n, below == n - 1 and Meta.class_level() == n, "до: %d, на пороге: %d" % [below, Meta.class_level()])
		line += " %d:%d" % [n, need]
	Meta.dna_earned = 0
	_check("level.start", Meta.class_level() == 1 and Meta.skill_points() == 0)
	print("METATEST class_level ДНК для уровня:%s" % line)


func _test_tree() -> void:
	Meta.reset()
	Meta.dna_earned = Meta.dna_for_level(10)
	_check("tree.points", Meta.class_level() == 10 and Meta.skill_points() == 9)
	_check("tree.order_locked", not Meta.can_unlock("fire_2") and not Meta.can_unlock("mag_3") and not Meta.unlock("surv_2") and not Meta.can_unlock("nope"))
	_check("tree.first_nodes", Meta.unlock("fire_1") and Meta.unlock("mag_1") and Meta.unlock("surv_1") and Meta.skill_points() == 6)
	_check("tree.no_double", not Meta.unlock("fire_1"))
	_check("tree.second_nodes", Meta.unlock("fire_2") and Meta.unlock("mag_2") and Meta.unlock("surv_2") and Meta.unlock("fire_3") and Meta.unlock("mag_3") and Meta.unlock("surv_3"))
	_check("tree.spent", Meta.skill_points() == 0 and Meta.tree.size() == 9)
	# очки кончились
	Meta.reset()
	Meta.dna_earned = 80
	_check("tree.one_point", Meta.skill_points() == 1 and Meta.unlock("mag_1") and not Meta.can_unlock("mag_2") and not Meta.unlock("fire_1"))
	# бонусы: ничего не открыто — нейтрально
	Meta.reset()
	var b := Meta.run_bonuses()
	_check("tree.neutral", b["damage_mul"] == 1.0 and b["crit_add"] == 0.0 and b["sustained_rate"] == 0.0 and b["reload_mul"] == 1.0 and b["mag_mul"] == 1.0
		and b["last_round"] == false and b["hp_add"] == 0.0 and b["dash_charges"] == 1 and b["adrenaline"] == false)
	Meta.apply_preset("maxed")
	b = Meta.run_bonuses()
	_check("tree.full", _near(b["damage_mul"], 1.08) and _near(b["crit_add"], 0.10) and _near(b["sustained_rate"], 0.20) and _near(b["reload_mul"], 0.85)
		and _near(b["mag_mul"], 1.20) and b["last_round"] == true and _near(b["hp_add"], 20.0) and b["dash_charges"] == 2 and b["adrenaline"] == true)
	print("METATEST tree: порядок узлов, очки, бонусы ок; maxed=%s" % str(b))
	Meta.reset()


# --- мастерская --------------------------------------------------------------------------------

func _test_workshop() -> void:
	Meta.reset()
	var serial: Array[int] = []
	var rare: Array[int] = []
	for level in 6:
		serial.append(Meta.upgrade_cost("ak_s", "damage"))
		rare.append(Meta.upgrade_cost("spear", "damage"))
		Meta.workshop["ak_s"] = {"damage": level + 1}
		Meta.workshop["spear"] = {"damage": level + 1}
	_check("workshop.cost_serial", serial == [20, 40, 70, 110, 160, -1], str(serial))
	_check("workshop.cost_rare", rare == [30, 60, 105, 165, 240, -1], str(rare))
	_check("workshop.cost_common", Meta.upgrade_cost("m4", "rate") == 20, "обычная модель — без наценки")
	_check("workshop.unknown", Meta.upgrade_cost("zzz", "damage") == -1 and Meta.upgrade_cost("ak_s", "zzz") == -1)
	Meta.reset()
	Meta.dna = 30
	_check("workshop.buy_ok", Meta.buy_upgrade("ak_s", "damage") and Meta.dna == 10 and Meta.workshop_level("ak_s", "damage") == 1)
	_check("workshop.buy_poor", not Meta.buy_upgrade("ak_s", "damage") and Meta.dna == 10 and Meta.workshop_level("ak_s", "damage") == 1)
	_check("workshop.not_owned", (func() -> bool:
		Meta.dna = 9999
		return not Meta.buy_upgrade("m4", "damage") and Meta.dna == 9999).call())
	Meta.owned.append("m4")
	var spent := 0
	for stat: String in Meta.WORKSHOP_STATS:
		for k in 5:
			spent += Meta.upgrade_cost("m4", stat)
			Meta.buy_upgrade("m4", stat)
	_check("workshop.max_all", spent == 4 * 400 and Meta.dna == 9999 - spent and not Meta.buy_upgrade("m4", "damage"), "потрачено %d" % spent)
	print("METATEST workshop: цены серийных %s, редких %s, ствол целиком %d ДНК" % [str(serial.slice(0, 5)), str(rare.slice(0, 5)), spent])
	Meta.reset()


# --- ящики --------------------------------------------------------------------------------------

func _test_crates() -> void:
	Meta.reset()
	_check("crate.empty", Meta.open_crate(false).is_empty() and Meta.open_crate(true).is_empty())
	var n := 10000
	for military in [false, true]:
		Meta.reset()
		Meta.rng.seed = 777 if military else 555
		if military:
			Meta.military_crates = n
		else:
			Meta.crates = n
		var kinds := {"model": 0, "dna": 0}
		var rare_n := 0
		var model_n := 0
		var dup_bad := 0
		var dna_sum := 0
		var dna_returned := 0
		var pack_min := 999
		var pack_max := 0
		var seen := {}
		var first_ok := true
		for k in n:
			var r := Meta.open_crate(military)
			kinds[r["kind"]] += 1
			dna_returned += int(r["dna"])
			if r["kind"] == "model":
				model_n += 1
				if r["rare"]:
					rare_n += 1
				if r["duplicate"]:
					if int(r["dna"]) != (100 if r["rare"] else 40):
						dup_bad += 1
				else:
					if seen.has(r["model"]) or int(r["dna"]) != 0:
						first_ok = false
				seen[r["model"]] = true
				var rarity: int = WeaponDefs.MODELS[r["model"]]["rarity"]
				if rarity != (WeaponDefs.Rarity.RARE if r["rare"] else WeaponDefs.Rarity.COMMON):
					dup_bad += 1
			else:
				pack_min = mini(pack_min, int(r["dna"]))
				pack_max = maxi(pack_max, int(r["dna"]))
				dna_sum += int(r["dna"])
		var label := "военный" if military else "обычный"
		var p_model := float(kinds["model"]) / n
		var p_rare := float(rare_n) / model_n
		var want_model := 0.8 if military else 0.5
		var want_rare := 0.5 if military else 0.15
		_check("crate.%s.model_share" % label, absf(p_model - want_model) <= 0.02, "%.3f" % p_model)
		_check("crate.%s.rare_share" % label, absf(p_rare - want_rare) <= 0.02, "%.3f" % p_rare)
		_check("crate.%s.pack_range" % label, pack_min >= 30 and pack_max <= 80, "%d..%d" % [pack_min, pack_max])
		_check("crate.%s.duplicates" % label, dup_bad == 0 and first_ok)
		_check("crate.%s.all_models" % label, seen.size() == 8, "выпало %d из 8" % seen.size())
		_check("crate.%s.dna_sum" % label, Meta.dna == dna_returned and Meta.crates + Meta.military_crates == 0)
		print("METATEST crate %s x%d: модель %.1f%% (цель %d), редкая среди моделей %.1f%% (цель %d), пачка %d..%d, ср. %.1f, дубликатов-ДНК ок" % [
			label, n, p_model * 100.0, want_model * 100.0, p_rare * 100.0, want_rare * 100.0, pack_min, pack_max, float(dna_sum) / maxi(kinds["dna"], 1)])
	# первое вскрытие модели открывает её, второе — дубликат
	Meta.reset()
	Meta.crates = 400
	var opened := {}
	var dup_seen := false
	for k in 400:
		var r := Meta.open_crate(false)
		if r["kind"] == "model":
			if opened.has(r["model"]):
				dup_seen = dup_seen or r["duplicate"]
			else:
				_check("crate.first_unlocks", not r["duplicate"] and Meta.is_owned(r["model"]))
			opened[r["model"]] = true
	_check("crate.duplicate_seen", dup_seen)
	Meta.reset()


func _test_favorites() -> void:
	Meta.reset()
	var base := WeaponDefs.Base.RIFLE
	_check("fav.default_serial", Meta.model_for(base) == "ak_s")
	_check("fav.not_owned", not Meta.set_favorite(base, "m4") and Meta.model_for(base) == "ak_s")
	Meta.owned.append("m4")
	_check("fav.wrong_base", not Meta.set_favorite(WeaponDefs.Base.SHOTGUN, "m4"))
	_check("fav.set", Meta.set_favorite(base, "m4") and Meta.model_for(base) == "m4")
	_check("fav.back", Meta.set_favorite(base, "ak_s") and Meta.model_for(base) == "ak_s")
	for b in WeaponDefs.BASES:
		_check("fav.serial_%d" % b, WeaponDefs.MODELS[Meta.model_for(b)]["rarity"] == WeaponDefs.Rarity.SERIAL)
	Meta.reset()


# --- статы ствола ----------------------------------------------------------------------------------

func _slot(model: String, level := 1) -> Weapons.Slot:
	_weapons.slots.clear()
	_weapons.add_weapon(WeaponDefs.MODELS[model]["base"], model)
	var s := _weapons.slots[0]
	s.level = level
	_weapons.refresh(0)
	s.mag = s.stats["mag"]
	return s


func _test_run_bonuses_stats() -> void:
	_weapons.passives = {}
	# без меты: ровно старые числа (BALANCE §3.3)
	Meta.reset()
	_weapons.bonuses = Meta.run_bonuses()
	var s := _slot("ak_s", 5)
	_check("stats.plain_l5", _near(s.stats["damage"], 13.0) and _near(s.stats["rate"], 6.9) and s.stats["mag"] == 45 and _near(s.stats["reload"], 1.05) and _near(s.stats["crit"], 0.0), str(s.stats))
	# АК-С L5 с мастерской 5/5 и деревом: урон 13·1.25·1.08, темп 6.9·1.2, магазин 45·1.5·1.2, перезарядка 1.05·0.7·0.85, крит +10%
	Meta.apply_preset("maxed")
	_weapons.bonuses = Meta.run_bonuses()
	s = _slot("ak_s", 5)
	var want_dmg := 13.0 * 1.25 * 1.08
	_check("stats.maxed_ak_l5", _near(s.stats["damage"], want_dmg) and _near(s.stats["rate"], 6.9 * 1.2) and s.stats["mag"] == 81
		and _near(s.stats["reload"], 1.05 * 0.7 * 0.85) and _near(s.stats["crit"], 0.10), str(s.stats))
	print("METATEST stats АК-С L5 maxed: урон %.3f (ожид. %.3f) темп %.2f магазин %d перезарядка %.4f крит %.2f" % [s.stats["damage"], want_dmg, s.stats["rate"], s.stats["mag"], s.stats["reload"], s.stats["crit"]])
	# Мясник L1 с одной мастерской, без дерева
	Meta.reset()
	Meta.workshop = {"butcher": {"damage": 2, "rate": 0, "mag": 4, "reload": 3}}
	_weapons.bonuses = Meta.run_bonuses()
	s = _slot("butcher", 1)
	_check("stats.workshop_butcher", _near(s.stats["damage"], 5.0 * 1.10) and s.stats["mag"] == 9 and _near(s.stats["reload"], 2.2 * 0.82) and s.stats["proj"] == 6, str(s.stats))
	# пассивки поверх меты: урон ×(1+0.1·2)
	Meta.reset()
	Meta.tree = {"fire_1": true}
	_weapons.bonuses = Meta.run_bonuses()
	_weapons.passives = {WeaponDefs.Passive.DAMAGE: 2}
	s = _slot("ak_s", 1)
	_check("stats.passive_stack", _near(s.stats["damage"], 7.0 * 1.08 * 1.2), str(s.stats))
	_weapons.passives = {}
	# мастерская влияет только на свою модель
	Meta.reset()
	Meta.workshop = {"colt": {"damage": 5}}
	_weapons.bonuses = Meta.run_bonuses()
	_check("stats.workshop_isolated", _near(_slot("bulldog", 1).stats["damage"], 30.0) and _near(_slot("colt", 1).stats["damage"], 14.0 * 1.25))
	Meta.reset()
	_weapons.bonuses = Meta.run_bonuses()


func _test_models_table() -> void:
	print("METATEST dps (BALANCE §3.1, стандартные патроны I): модель L1 / L5")
	_check("models.count", WeaponDefs.MODELS.size() == 16 and WeaponDefs.MODEL_ORDER.size() == 16)
	var traits := {}
	for id: String in WeaponDefs.MODEL_ORDER:
		var m: Dictionary = WeaponDefs.MODELS[id]
		_check("models.%s.fields" % id, m.has("base") and m.has("name") and m.has("short") and m.has("gun") and m.has("trait") and WeaponDefs.BASES.has(m["base"]))
		if m["trait"] != "":
			traits[m["trait"]] = id
			_check("models.%s.trait_text" % id, WeaponDefs.TRAITS.has(m["trait"]) and m["rarity"] != WeaponDefs.Rarity.SERIAL)
		# модель создаётся и стреляет статами без ошибок на всех уровнях
		for level in range(1, 6):
			var s := _slot(id, level)
			_check("models.%s.stats_l%d" % [id, level], s.stats["damage"] > 0.0 and s.stats["mag"] > 0 and s.stats["rate"] > 0.0 and s.stats["reload"] > 0.0)
		print("METATEST   %-10s %-8s %-9s L1=%6.2f L5=%6.2f  %s" % [id, WeaponDefs.RARITY_NAMES[m["rarity"]], m["short"], WeaponDefs.effective_dps(id, 1), WeaponDefs.effective_dps(id, 5), m["trait"]])
	_check("models.eight_traits", traits.size() == 8, str(traits.keys()))
	for base in WeaponDefs.BASES:
		var list := WeaponDefs.models_of(base)
		_check("models.pair_%d" % base, list.size() == 2 and WeaponDefs.MODELS[list[0]]["rarity"] == WeaponDefs.Rarity.SERIAL and WeaponDefs.MODELS[list[1]]["rarity"] != WeaponDefs.Rarity.SERIAL)
	# голос: нет файлов модели — голос серийной модели категории
	var s := _slot("m4")
	_weapons.sfx = _g.sfx
	var shot := _weapons.sound_id(s, "shot")
	_check("models.sfx_fallback", shot == "weapons/rifle/shot" or _g.sfx.has("weapons/m4/shot"), shot)
	_check("models.sfx_serial", _weapons.sound_id(_slot("ak_s"), "shot") == "weapons/rifle/shot")
	print("METATEST sfx: «М4» играет %s (файлов weapons/m4 %s)" % [shot, "есть" if _g.sfx.has("weapons/m4/shot") else "пока нет, голос серийной модели"])
	await _g.get_tree().physics_frame


# --- игрок: дерево ----------------------------------------------------------------------------------

func _test_player_bonuses() -> void:
	Meta.reset()
	Meta.apply_preset("maxed")
	_player.apply_bonuses(Meta.run_bonuses())
	_weapons.bonuses = Meta.run_bonuses()
	_check("player.hp", _near(_player.max_hp, 120.0) and _near(_player.hp, 120.0))
	_check("player.dash_charges", _player.dash_max == 2 and _player.dash_left == 2)
	var s := _slot("ak_s")
	s.mag = 3
	s.reloading = true
	_check("player.dash_first", _player.try_dash() and _player.dash_left == 1)
	_check("player.adrenaline_refill", not s.reloading and s.mag == s.stats["mag"] and _player.adrenaline_cd > 9.9, "mag=%d reloading=%s" % [s.mag, str(s.reloading)])
	s.mag = 3
	_check("player.dash_second", _player.try_dash() and _player.dash_left == 0)
	_check("player.adrenaline_cooldown", s.mag == 3, "второй рывок в КД не должен заряжать")
	_check("player.dash_empty", not _player.try_dash())
	_player._recharge_dash(1.0)
	_check("player.recharge_partial", _player.dash_left == 0)
	_player._recharge_dash(1.1)
	_check("player.recharge_one", _player.dash_left == 1 and _player.dash_cd > 1.9, "dash_left=%d cd=%.2f" % [_player.dash_left, _player.dash_cd])
	_player._recharge_dash(2.1)
	_check("player.recharge_full", _player.dash_left == 2 and _player.dash_cd == 0.0)
	_player.adrenaline_cd = 0.05
	_player._physics_process(0.1)
	_check("player.adrenaline_ready", _player.adrenaline_cd == 0.0)
	s.mag = 1
	_player.try_dash()
	_check("player.adrenaline_again", s.mag == s.stats["mag"])
	# без дерева: один заряд, 100 HP, без адреналина
	Meta.reset()
	_player.apply_bonuses(Meta.run_bonuses())
	_check("player.plain", _near(_player.max_hp, 100.0) and _player.dash_max == 1 and not _player.adrenaline)
	_check("player.plain_dash", _player.try_dash() and not _player.try_dash() and _player.dash_cd > 1.9)
	_player._recharge_dash(2.1)
	_check("player.plain_recharge", _player.dash_left == 1)
	_player._iframes = 0.0
	print("METATEST player: HP 120, 2 заряда рывка, адреналин КД %.0f с, без дерева 100 HP/1 заряд ок" % Meta.ADRENALINE_COOLDOWN)
	await _g.get_tree().physics_frame


# --- вспомогательное для боя ----------------------------------------------------------------------

func _clear_field() -> void:
	for e in _horde.count:
		_horde.dead[e] = 1
	_horde._compact()
	_weapons.clear_projectiles()
	_shot_frames.clear()


## Неподвижная цель на смещении off от игрока. Возвращает uid (индекс может поменяться).
func _dummy(off: Vector2, hp := 1.0e6) -> int: # HP — float32: миллиона хватает, и мелкий урон ещё виден
	var e := _horde.spawn(_player.position + off)
	_horde.speed[e] = 0.0
	_horde.hp[e] = hp
	_horde.max_hp[e] = hp
	_horde.touch_cd[e] = 1.0e9
	return _horde.uid[e]


func _idx(uid: int) -> int:
	for e in _horde.count:
		if _horde.uid[e] == uid:
			return e
	return -1


func _hp(uid: int) -> float:
	var e := _idx(uid)
	return _horde.hp[e] if e >= 0 else -1.0


func _step(n: int) -> void:
	_horde._rebuild_grid()
	for k in n:
		_frame += 1
		_weapons._physics_process(DT)


## Стрельба без случайности: крит выключен у ствола.
func _no_crit(s: Weapons.Slot) -> void:
	s.stats["crit"] = -5.0


func _prepare(model: String, level := 1) -> Weapons.Slot:
	_clear_field()
	_weapons.bonuses = Meta.run_bonuses()
	var s := _slot(model, level)
	_no_crit(s)
	_player.is_dead = false
	return s


# --- последний патрон, шквал огня -----------------------------------------------------------------

func _test_last_round() -> void:
	Meta.reset()
	Meta.tree = {"mag_3": true}
	var s := _prepare("ak_s")
	_dummy(Vector2(80, 0))
	s.mag = 3
	var damages: Array[float] = []
	var shots := 0
	while shots < 3:
		_step(1)
		if _shot_frames.size() > shots:
			shots = _shot_frames.size()
			damages.append(s.last_damage)
		if _frame > 100000:
			break
	_check("last_round.x3", damages.size() == 3 and _near(damages[0], 7.0) and _near(damages[1], 7.0) and _near(damages[2], 21.0), str(damages))
	# последний патрон убивает гибами, обычный выстрел с тем же уроном — нет
	var gibs := [0, 0]
	var on_kill := func(_p: Vector2, _d: Vector2, death: int, _f: float, _v: int) -> void:
		gibs[0] += 1
		if death == Gore.Death.GIBS:
			gibs[1] += 1
	_horde.enemy_killed.connect(on_kill)
	for last in [false, true]:
		gibs[0] = 0
		gibs[1] = 0
		s = _prepare("ak_s")
		var weak := _dummy(Vector2(60, 0), 15.0)
		s.mag = 1 if last else 5
		s.stats["damage"] = 20.0 # 20 урона: убивает и без ×3, «оверкилл» не выше max_hp
		_horde.max_hp[_idx(weak)] = 100.0 # чтобы обычная смерть не считалась оверкиллом
		_step(60)
		_check("last_round.gibs_%s" % str(last), gibs[0] == 1 and (gibs[1] == 1) == last, "убито %d гибов %d" % [gibs[0], gibs[1]])
	_horde.enemy_killed.disconnect(on_kill)
	Meta.reset()
	_weapons.bonuses = Meta.run_bonuses()
	print("METATEST last_round: урон последнего патрона ×3 (%s), убитый рвётся на гибы ок" % str(damages))
	await _g.get_tree().physics_frame


func _test_sustained() -> void:
	Meta.reset()
	Meta.tree = {"fire_3": true}
	var s := _prepare("ak_s")
	s.stats["mag"] = 9999
	s.mag = 9999
	_dummy(Vector2(90, 0))
	_step(60 * 6)
	var early := 0
	var late := 0
	for f in _shot_frames:
		if f > _shot_frames[0] + 30 and f <= _shot_frames[0] + 150:
			early += 1 # секунды 0.5–2.5
		elif f > _shot_frames[0] + 240 and f <= _shot_frames[0] + 360:
			late += 1 # секунды 4–6
	# 2 секунды: 6 выстр/с → ~12, после 3 с: 7.2/с → ~14.4
	_check("sustained.rate_up", late > early and _weapons._streak_mult(s) == 1.2, "ранние %d, поздние %d за 2 с" % [early, late])
	_step(120)
	s.cooldown = 1.0e9
	_step(60) # пауза 1 с — серия сброшена
	_check("sustained.reset_after_pause", s.streak == 0.0, "streak=%.2f" % s.streak)
	Meta.reset()
	print("METATEST sustained: за 2 с до 3 с стрельбы %d выстрелов, после — %d (+20%%)" % [early, late])
	await _g.get_tree().physics_frame


# --- черты моделей -----------------------------------------------------------------------------------

## Группы выстрелов: подряд идущие с интервалом ≤ gap кадров.
func _groups(gap: int) -> Array[int]:
	var out: Array[int] = []
	var size := 0
	var last := -1000
	for f in _shot_frames:
		if f - last > gap and size > 0:
			out.append(size)
			size = 0
		size += 1
		last = f
	if size > 0:
		out.append(size)
	return out


func _test_trait_burst3() -> void:
	Meta.reset()
	var s := _prepare("m4")
	s.stats["mag"] = 9999
	s.mag = 9999
	_dummy(Vector2(100, 0))
	_step(60 * 4)
	var groups := _groups(8)
	_check("burst3.groups_of_three", groups.size() >= 5 and groups.slice(0, groups.size() - 1).all(func(n: int) -> bool: return n == 3), str(groups))
	_check("burst3.heat_flat", s.heat == 0.0, "heat=%.2f" % s.heat)
	var rate := float(_shot_frames.size()) / 4.0
	_check("burst3.rate", absf(rate - 5.0) < 0.9, "%.2f выстр/с" % rate)
	# контроль: у АК-С разброс растёт
	var ak := _prepare("ak_s")
	ak.stats["mag"] = 9999
	ak.mag = 9999
	_dummy(Vector2(100, 0))
	_step(60)
	_check("burst3.control_ak_heat", ak.heat > 3.0, "heat=%.2f" % ak.heat)
	print("METATEST trait burst3 (М4): очереди %s, темп %.2f/с, разброс +%.1f° (АК-С +%.1f°)" % [str(groups.slice(0, 6)), rate, s.heat, ak.heat])
	await _g.get_tree().physics_frame


func _test_trait_slamfire() -> void:
	Meta.reset()
	var s := _prepare("shkval")
	_dummy(Vector2(70, 0))
	_check("slamfire.stats", s.stats["mag"] == 10 and s.stats["rate"] >= 2.0 and s.stats["reload"] > _slot("butcher").stats["reload"] and s.stats["rate"] > 1.1 * 1.9)
	s = _prepare("shkval")
	_dummy(Vector2(70, 0))
	_step(60 * 5)
	_check("slamfire.ten_shots_then_reload", _shot_frames.size() == 10 and (s.reloading or s.mag == 10), "выстрелов %d" % _shot_frames.size())
	_check("slamfire.no_pump", s.rack_t < 0.0, "затвор не должен дёргаться")
	var span := float(_shot_frames[-1] - _shot_frames[0]) / 60.0
	print("METATEST trait slamfire (Шквал): 10 выстрелов за %.2f с (%.2f/с), магазин 10, перезарядка %.1f с, без помпы" % [span, 9.0 / span, s.stats["reload"]])
	await _g.get_tree().physics_frame


func _test_trait_kill_charge() -> void:
	Meta.reset()
	var s := _prepare("spear")
	var weak := _dummy(Vector2(60, 0), 1.0)
	var tank := _dummy(Vector2(-90, 0))
	var before := _hp(tank)
	_step(1)
	var first_damage := s.last_damage
	_step(30)
	_check("kill_charge.charged_after_kill", s.charged and _hp(weak) <= 0.0, "charged=%s" % str(s.charged))
	s.cooldown = 0.0
	var tank_hp := _hp(tank)
	_check("kill_charge.first_beam_missed_tank", tank_hp == before, "первый луч задел танка")
	_step(1)
	var charged_damage := s.last_damage
	var after_charged := _hp(tank)
	_check("kill_charge.hit_x1_5", _near(before - after_charged, 60.0 * 1.5) and _near(charged_damage, 90.0), "потеряно %.1f, last_damage %.1f" % [before - after_charged, charged_damage])
	_check("kill_charge.consumed", not s.charged)
	s.cooldown = 0.0
	_step(1)
	_check("kill_charge.next_normal", _near(after_charged - _hp(tank), 60.0) and _near(s.last_damage, 60.0), "потеряно %.1f" % (after_charged - _hp(tank)))
	print("METATEST trait kill_charge (Копьё): выстрел %.0f → убийство → следующий %.0f (×1.5) → снова %.0f" % [first_damage, charged_damage, s.last_damage])
	await _g.get_tree().physics_frame


func _test_trait_sticky() -> void:
	Meta.reset()
	var s := _prepare("hive")
	var tank := _dummy(Vector2(110, 0))
	var hp0 := _hp(tank)
	var stuck_frame := -1
	var boom_frame := -1
	var carried := false
	var max_stuck := 0
	var follows := false
	var tank_uid := tank
	for f in 120:
		_step(1)
		max_stuck = maxi(max_stuck, _weapons._xpos.size())
		if stuck_frame < 0 and _weapons._xpos.size() > 0:
			stuck_frame = _frame
			_check("sticky.not_instant", _hp(tank) == hp0, "взрыв при касании")
		var slot := _weapons._xuid.find(tank_uid)
		if slot >= 0 and not carried:
			carried = true
			var offset := _weapons._xpos[slot] - _horde.pos[_idx(tank)]
			_horde.pos[_idx(tank)] += Vector2(20, 0) # носитель сдвинулся — граната едет с ним
			var left := _weapons._xt[slot]
			_weapons._update_stuck(0.0)
			follows = _weapons._xpos[slot].distance_to(_horde.pos[_idx(tank)] + offset) < 0.5 and left > 0.0
		if stuck_frame >= 0 and boom_frame < 0 and _weapons._xpos.size() < max_stuck:
			boom_frame = _frame # первая из гранат кассеты взорвалась
			break
	_check("sticky.stuck_to_enemy", stuck_frame > 0 and carried, "прилипания к врагу не было")
	_check("sticky.follows_carrier", follows)
	var fuse := float(boom_frame - stuck_frame) / 60.0
	_check("sticky.fuse_0_6", boom_frame > 0 and absf(fuse - 0.6) <= 0.06, "через %.2f с" % fuse)
	_step(30)
	_check("sticky.exploded", _hp(tank) < hp0, "носитель цел")
	_check("sticky.cluster_three", s.stats["proj"] == 3 and max_stuck == 3, "прилипло %d" % max_stuck)
	print("METATEST trait sticky (Улей): кассета из %d, прилипание → взрыв через %.2f с (едет с носителем), носитель потерял %.0f HP" % [max_stuck, fuse, hp0 - _hp(tank)])
	# граната на земле (промах) тоже рвётся через запал
	_prepare("hive")
	_horde._rebuild_grid()
	_weapons._stick(_player.position + Vector2(300, 300), 0, 10.0, 34.0, Weapons.G_STICKY)
	_check("sticky.ground", _weapons._xuid[0] == 0 and _weapons._xpos.size() == 1)
	_step(40)
	_check("sticky.ground_boom", _weapons._xpos.size() == 0)
	await _g.get_tree().physics_frame


func _test_trait_hicap() -> void:
	Meta.reset()
	var s := _prepare("guard")
	var colt := _slot("colt")
	_check("hicap.stats", s.stats["mag"] == 17 and s.stats["rate"] > colt.stats["rate"] and s.stats["damage"] < colt.stats["damage"] and s.stats["mag"] > 2 * colt.stats["mag"])
	s = _prepare("guard")
	_dummy(Vector2(90, 0))
	var reload_seen_at := -1
	for f in 60 * 8:
		_step(1)
		if s.reloading and reload_seen_at < 0:
			reload_seen_at = _shot_frames.size()
	_check("hicap.seventeen_then_reload", reload_seen_at == 17, "перезарядка после %d выстрелов" % reload_seen_at)
	print("METATEST trait hicap (Страж): магазин %d, %.1f выстр/с, урон %.0f; перезарядка после %d выстрелов" % [s.stats["mag"], s.stats["rate"], s.stats["damage"], reload_seen_at])
	await _g.get_tree().physics_frame


func _test_trait_fan() -> void:
	Meta.reset()
	var s := _prepare("cowboy")
	var targets: Array[int] = []
	for k in 5:
		targets.append(_dummy(Vector2.from_angle(TAU * k / 5.0) * (60.0 + k * 12.0)))
	var hp0: Array[float] = []
	for t in targets:
		hp0.append(_hp(t))
	_step(1)
	_check("fan.starts_at_once", _shot_frames.size() == 1 and s.fan_left == 5, "выстрелов %d, осталось %d" % [_shot_frames.size(), s.fan_left])
	_step(80)
	var span := float(_shot_frames[-1] - _shot_frames[0]) / 60.0
	_check("fan.six_shots_in_half_second", _shot_frames.size() == 6 and span <= 0.55 and span >= 0.3, "выстрелов %d за %.2f с" % [_shot_frames.size(), span])
	var hit := 0
	for k in targets.size():
		if _hp(targets[k]) < hp0[k]:
			hit += 1
	_check("fan.different_targets", hit == 5, "задето целей: %d" % hit)
	_check("fan.empties_cylinder_reloads", s.mag == 0 and s.reloading)
	# единственная цель: веер идёт по ней же, барабан высаживается
	s = _prepare("cowboy")
	var one := _dummy(Vector2(80, 0))
	var one_hp := _hp(one)
	_step(90)
	_check("fan.single_target_all_six", _shot_frames.size() == 6 and _hp(one) < one_hp, "выстрелов %d" % _shot_frames.size())
	print("METATEST trait fan (Ковбой): 6 выстрелов за %.2f с по %d разным целям, барабан пуст → перезарядка" % [span, hit])
	await _g.get_tree().physics_frame


func _test_trait_steady() -> void:
	Meta.reset()
	var s := _prepare("osa")
	s.stats["crit"] = -5.0
	_check("steady.mag50", s.stats["mag"] == 50)
	_dummy(Vector2(70, 0))
	_step(60 * 4)
	var osa_shots := _shot_frames.size()
	_check("steady.heat_flat", s.heat == 0.0 and osa_shots > 35, "heat=%.2f, выстрелов %d" % [s.heat, osa_shots])
	var ppsh := _prepare("ppsh")
	_dummy(Vector2(70, 0))
	_step(60)
	_check("steady.control_ppsh_heat", ppsh.heat > 5.0, "heat=%.2f" % ppsh.heat)
	print("METATEST trait steady (Оса): магазин 50, за 4 с %d выстрелов, разброс +%.1f° (ППШ за 1 с +%.1f°)" % [osa_shots, s.heat, ppsh.heat])
	await _g.get_tree().physics_frame


func _test_trait_lever() -> void:
	Meta.reset()
	var s := _prepare("winchester")
	var weak := _dummy(Vector2(100, 0), 1.0)
	var tank := _dummy(Vector2(-110, 0))
	var normal_interval := 1.0 / float(s.stats["rate"])
	_step(1)
	var first_frame := _shot_frames[0]
	for f in 60:
		_step(1)
		if _shot_frames.size() >= 2:
			break
	var with_kill := float(_shot_frames[1] - first_frame) / 60.0 if _shot_frames.size() >= 2 else 9.9
	_check("lever.kill_cocks_instantly", with_kill < normal_interval * 0.7 and _hp(weak) <= 0.0, "интервал после убийства %.2f с, обычный %.2f с" % [with_kill, normal_interval])
	# без убийства — полный интервал
	var before := _shot_frames.size()
	for f in 90:
		_step(1)
		if _shot_frames.size() > before:
			break
	var plain := float(_shot_frames[-1] - _shot_frames[-2]) / 60.0
	_check("lever.plain_interval", absf(plain - normal_interval) <= 0.04, "%.2f с против %.2f с" % [plain, normal_interval])
	var mosin := _slot("mosin")
	_check("lever.stats", s.stats["rate"] > 1.9 * mosin.stats["rate"] and s.stats["damage"] < 0.65 * mosin.stats["damage"], str(s.stats))
	print("METATEST trait lever (Винчестер): интервал %.2f с, после убийства следующий выстрел через %.2f с; урон %.1f (Мосинка %.0f), темп %.1f/с" % [normal_interval, with_kill, s.stats["damage"], mosin.stats["damage"], s.stats["rate"]])
	_clear_field()
	await _g.get_tree().physics_frame


# --- итоги забега -------------------------------------------------------------------------------------

func _test_results_screen() -> void:
	Meta.reset()
	var stats := {"victory": true, "time": 600.0, "kills": 3000, "elites": 12, "best_combo": 90, "blood_liters": 1.0, "weapons": [], "crates": 2,
		"military_crates": 1, "dna_lines": [["Время × 10", 100]], "dna_mult": 1.5, "dna_total": 186}
	_g.results.open(stats)
	_check("results.add_run", Meta.dna == 186 and Meta.dna_earned == 186 and Meta.crates == 2 and Meta.military_crates == 1 and Meta.runs == 1)
	_check("results.bank_line", int(_g.results._stats["dna_bank"]) == 186)
	_g.results.visible = false
	Meta.add_run({"dna_total": 100, "crates": 0, "military_crates": 0})
	_check("meta.add_run_accumulates", Meta.dna == 286 and Meta.dna_earned == 286 and Meta.runs == 2 and Meta.class_level() == 3)
	Meta.reset()
