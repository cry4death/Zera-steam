extends Node
## Мета-прогресс между забегами (CONTRACTS §12, BALANCE §11, GDD §12.1): ДНК, уровень класса и дерево,
## мастерская моделей, оружейные ящики, избранные модели. Автозагрузка «Meta».
##
## Файл user://zera_save.json (JSON, версия схемы, запись через временный файл). Битый или чужой
## файл уходит в резервную копию, игра начинает с чистого. Тест-режимы игры работают на сохранении
## «в памяти»: настоящее не читают и не пишут.
##
## Флаги командной строки (после --):
##   --fresh-save          чистое состояние, ничего не пишется на диск
##   --meta=<json>         подмешать поля состояния (dna, dna_earned, tree, workshop, owned, favorite, crates…)
##   --meta-preset=maxed   полный допустимый путь дерева, мастерская 5/5, все модели, много ДНК
##   --save-file=<путь>    писать и читать этот файл (user://имя.json) даже в тест-режиме: проверка перезапуска

const SAVE_VERSION := 10
const FIRST_HINTS := ["move", "aim", "xp", "card", "pickup", "ability", "trader", "evac"]
var first_run: Dictionary = {}
const ENDLESS_MAPS := ["quarantine_checkpoint", "old_town", "open_perimeter"]
const ENDLESS_MAP_NAMES := ["Блокпост", "Старый город", "Периметр"]
const ENDLESS_MILESTONES := [900, 1200, 1800]
const ENDLESS_DNA_PER_MINUTE := 4
const ENDLESS_CRATE_MINUTES := 10
const ENDLESS_CRATE_CAP := 3
var endless_records: Dictionary = {}
const DEFAULT_SETTINGS := {"master": 1.0, "weapons": 1.0, "world": 1.0, "ui": 1.0, "music": 1.0,
	"gore": 2, "shake": 1.0, "fullscreen": true, "auto_fire": true, "reduce_motion": false,
	"ui_scale": 1.0, "screen_flashes": true, "screen_blood": true, "camera_recoil": 1.0,
	"alarm_blink": true, "effects": 1.0, "bindings": SettingsBindings.DEFAULTS}
signal settings_changed
var settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)
const SAVE_PATH := "user://zera_save.json"
## Любой из этих флагов (по началу строки) — тест-режим игры: сохранение только в памяти.
const TEST_FLAGS := ["--class-shots", "--class-tree-test", "--c6-test", "--c6-capture", "--q1-test", "--pack-test", "--obstacles-test", "--map-test", "--map-shots", "--globe-test", "--c2-checks", "--guns-test", "--fx-test", "--hud-test", "--campaign-test", "--campaign-op", "--base-test", "--aim-test", "--audio-test", "--sim", "--bench", "--boss", "--alarm", "--ui-test", "--weapons-test", "--loadout", "--s3-test", "--meta-test", "--kinds", "--gore-stress", "--fresh-save"]

# Уровень класса: накоплено ДНК для уровня n = 80 · (n − 1)^1.5 (BALANCE §11.2)
const LEVEL_DNA_K := 80.0
const MAX_CLASS_LEVEL := 99

## Каталог отдельно от профиля; прежние id оставлены для диагностики и внешних сценариев.
const TREE := ClassTree.BRANCHES
const ADRENALINE_COOLDOWN := 10.0

# Мастерская (BALANCE §11.3): 4 стата × 5 уровней, ДНК тратится.
const WORKSHOP_STATS := ["damage", "rate", "mag", "reload"]
const WORKSHOP_NAMES := {"damage": "Урон", "rate": "Скорострельность", "mag": "Магазин", "reload": "Перезарядка"}
const WORKSHOP_STEP := {"damage": 0.05, "rate": 0.04, "mag": 0.10, "reload": -0.06} # за уровень
const WORKSHOP_COSTS := [20, 40, 70, 110, 160]
const WORKSHOP_MAX := 5

# Ящики (BALANCE §11.4): шанс новой модели, редкая модель, пачка ДНК, дубликат
const CRATE_MODEL_CHANCE := 0.5
const CRATE_RARE_CHANCE := 0.15
const MILITARY_MODEL_CHANCE := 0.8
const MILITARY_RARE_CHANCE := 0.5
const DNA_PACK_MIN := 30
const DNA_PACK_MAX := 80
const DUPLICATE_DNA := {false: 40, true: 100} # обычная / редкая

var dna := 0 # тратимая
var dna_earned := 0 # всего заработано (уровень класса), не тратится
var tree := {} # id узла → true
var class_id := "assault"
var class_trees: Dictionary = {}
var tree_gates: Dictionary = {} # постоянные отметки допуска, без награды очками
var workshop := {} # model_id → {"damage": 0..5, "rate": .., "mag": .., "reload": ..}
var owned := PackedStringArray() # открытые модели (серийные — всегда)
var favorite := {} # Base → model_id
var crates := 0
var military_crates := 0
var runs := 0
var campaign: Dictionary = {}
var campaign_recovered := false
var last_save_ok := true
var save_calls := 0 # диагностика числа транзакций

var persist := true # false — состояние только в памяти (тест-режимы)
var save_path := SAVE_PATH
var rng := RandomNumberGenerator.new()
var last_error := "" # причина последнего сбоя загрузки/записи (для тестов и отладки)
var last_run := {} # что дал последний add_run: {"dna", "crates", "military_crates"}


var _settings_dirty := false
var _settings_delay := 0.0
var test_errors := 0
var _test_aborted := false
var _test_logger: Logger


class TestLogger extends Logger:
	var owner: Node

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _backtraces: Array[ScriptBacktrace]) -> void:
		if error_type != Logger.ERROR_TYPE_WARNING:
			owner.test_errors += 1
			owner.call_deferred("_test_abort")


func _run_pad_cycle() -> void:
	await MetaTest.run_pad_cycle(self)


func _inject_test_error() -> void:
	assert(false, "Q1 deliberate SCRIPT ERROR")


func _test_abort() -> void:
	if _test_aborted:
		return
	_test_aborted = true
	print("TESTRESULT ok=false errors=%d" % test_errors)
	get_tree().quit(1)


func finish_test(code := 0) -> void:
	if test_errors > 0:
		_test_abort()
	else:
		get_tree().quit(code)


func _process(delta: float) -> void:
	if _settings_dirty:
		_settings_delay -= delta
		if _settings_delay <= 0.0:
			flush_settings()


func flush_settings() -> void:
	if _settings_dirty:
		_settings_dirty = false
		save()


func _exit_tree() -> void:
	flush_settings()
	if _test_logger != null:
		OS.remove_logger(_test_logger)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if is_test_run() or OS.get_cmdline_user_args().has("--q1-pad-cycle"):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
		_test_logger = TestLogger.new()
		_test_logger.owner = self
		OS.add_logger(_test_logger)
		if OS.get_cmdline_user_args().has("--test-fail=script"):
			_inject_test_error()
	rng.randomize()
	reset()
	var args := OS.get_cmdline_user_args()
	if args.has("--q1-pad-cycle"):
		persist = false
		settings["fullscreen"] = false
		_run_pad_cycle.call_deferred()
		return
	# Эти проверки никогда не читают профиль, даже с --save-file.
	if args.has("--base-test") or args.has("--campaign-test") or args.has("--globe-test") or args.has("--cp1-capture") or args.has("--c2-checks"):
		persist = false
		return
	var custom := ""
	for a in args:
		if a.begins_with("--save-file="):
			custom = a.trim_prefix("--save-file=")
	if custom != "":
		save_path = custom
		load_save()
	elif is_test_run(args):
		persist = false
	else:
		load_save()
	_apply_cmdline(args)
	apply_settings()


## Неизвестные ключи и неверные типы не попадают в сохранение.
func clean_settings(value: Variant) -> Dictionary:
	var out := DEFAULT_SETTINGS.duplicate(true)
	out["bindings"] = SettingsBindings.defaults()
	if not value is Dictionary:
		return out
	for key: String in out:
		var v: Variant = value.get(key)
		if key == "bindings":
			out[key] = SettingsBindings.clean(v)
		elif key in ["fullscreen", "auto_fire", "reduce_motion", "screen_flashes", "screen_blood", "alarm_blink"]:
			if v is bool:
				out[key] = v
		elif _is_num(v) and is_finite(float(v)):
			if key == "ui_scale":
				out[key] = clampf(float(v), 0.8, 1.5)
			else:
				out[key] = clampi(int(v), 0, 2) if key == "gore" else clampf(float(v), 0.0, 1.0)
	return out


func set_setting(key: String, value: Variant, deferred_save := false) -> void:
	var next := settings.duplicate()
	next[key] = value
	var clean := clean_settings(next)
	if settings == clean:
		return
	settings = clean
	apply_settings()
	if deferred_save:
		_settings_dirty = true
		_settings_delay = 0.5
	else:
		_settings_dirty = false
		save()


func apply_settings() -> void:
	SettingsBindings.apply(settings["bindings"])
	for key: String in ["master", "weapons", "world", "ui", "music"]:
		var gain := float(settings[key]) * (float(settings["effects"]) if key in ["weapons", "world"] else 1.0)
		var trim: float = {"weapons": -9.0, "world": -12.0, "music": -7.0}.get(key, 0.0)
		# W4: выстрелы игрока идут по шине Shots и подчиняются тому же ползунку «оружие».
		var names: Array[String] = [key.capitalize() if key != "ui" else "UI"]
		if key == "weapons":
			names.append("Shots")
		for bus_name in names:
			var bus := AudioServer.get_bus_index(bus_name)
			if bus < 0:
				continue
			AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(gain, 0.0001)) + (-1.0 if bus_name == "Shots" else trim))
			AudioServer.set_bus_mute(bus, gain <= 0.0)
	if DisplayServer.get_name() != "headless" and not is_test_run() and not OS.get_cmdline_user_args().has("--base-test"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED)
	settings_changed.emit()


func gore_multiplier() -> float:
	return [0.18, 0.55, 1.0][int(settings["gore"])]


## Запущен ли любой тест-режим игры (флаги из TEST_FLAGS). S6 использует то же для маршрутизации сцен.
static func is_test_run(args: PackedStringArray = OS.get_cmdline_user_args()) -> bool:
	if args.has("--endless-test") or args.has("--endless-shots"):
		return true
	for a in args:
		for f: String in TEST_FLAGS:
			if a.begins_with(f):
				return true
	return false


# --- уровень класса и дерево ---------------------------------------------------------------

## Сколько накопленной ДНК нужно для уровня n (уровень 1 — с нуля).
static func dna_for_level(n: int) -> int:
	return 0 if n <= 1 else roundi(LEVEL_DNA_K * pow(n - 1, 1.5))


func class_level() -> int:
	var n := 1
	while n < MAX_CLASS_LEVEL and dna_earned >= dna_for_level(n + 1):
		n += 1
	return n


func skill_points() -> int:
	return maxi(class_level() - 1 - tree_spent(), 0)


func tree_spent() -> int:
	var spent := 0
	for id: String in tree:
		spent += int(ClassTree.node(id).get("cost", 0))
	return spent


## Все узлы в порядке «ветка по ветке».
static func node_ids() -> Array[String]:
	return ClassTree.ids()


## Можно ли открыть узел: он существует, закрыт, предыдущий в ветке открыт, есть очко навыка.
func can_unlock(node: String) -> bool:
	return unlock_reason(node).is_empty()


func refresh_tree_gates() -> void:
	if runs >= 5:
		tree_gates["runs5"] = true
	if runs >= 10:
		tree_gates["runs10"] = true
	for id: String in ["object_7", "mother"]:
		var nest: Dictionary = campaign.get("nests", {}).get(id, {})
		if nest.get("alive", true) == false:
			tree_gates["nest"] = true


func unlock_reason(id: String) -> String:
	var n := ClassTree.node(id)
	if n.is_empty():
		return "Нет такого навыка"
	if tree.has(id):
		return "Навык открыт"
	if tree.has(n["exclude"]):
		return "Выбрано: " + str(ClassTree.node(n["exclude"])["name"])
	if not ClassTree.parents_met(n, tree):
		return "Нужен любой соседний узел"
	refresh_tree_gates()
	var gate: String = n.get("gate", "")
	if not gate.is_empty() and not tree_gates.has(gate):
		return {"runs5": "Завершите 5 вылазок (%d/5)" % mini(runs, 5), "runs10": "Завершите 10 вылазок (%d/10)" % mini(runs, 10), "nest": "Уничтожьте улей Объект-7 или Матку"}[gate]
	if skill_points() < int(n["cost"]):
		return "Нужно %d очк. · есть %d" % [n["cost"], skill_points()]
	return ""


func reset_tree() -> int:
	var refunded := tree_spent()
	if refunded > 0:
		tree.clear()
		save()
	return refunded


func unlock(node: String) -> bool:
	if not can_unlock(node):
		return false
	tree[node] = true
	save()
	return true


## Бонусы забега из дерева. Закрытый узел даёт нейтральное значение.
## dash_charges — всего зарядов рывка (1 или 2), sustained_rate — доля прироста темпа после 3 с стрельбы.
func run_bonuses() -> Dictionary:
	return ClassTree.bonuses(tree)


func select_class(id: String) -> void:
	if not id in ClassTree.CLASSES: return
	class_trees[class_id] = tree.duplicate()
	class_id = id
	ClassTree.active = id
	tree = class_trees.get(id, {}).duplicate()
	save()


# --- мастерская -------------------------------------------------------------------------------

func is_owned(model: String) -> bool:
	if not WeaponDefs.MODELS.has(model):
		return false
	return WeaponDefs.MODELS[model]["rarity"] == WeaponDefs.Rarity.SERIAL or owned.has(model)


func workshop_level(model: String, stat: String) -> int:
	var w: Dictionary = workshop.get(model, {})
	return int(w.get(stat, 0))


## Цена следующего уровня; −1 — максимум или нет такой модели/стата. Редкие модели ×1.5.
func upgrade_cost(model: String, stat: String) -> int:
	if not WeaponDefs.MODELS.has(model) or not WORKSHOP_STATS.has(stat):
		return -1
	var level := workshop_level(model, stat)
	if level >= WORKSHOP_MAX:
		return -1
	var cost: float = WORKSHOP_COSTS[level]
	if WeaponDefs.MODELS[model]["rarity"] == WeaponDefs.Rarity.RARE:
		cost *= WeaponDefs.RARE_MULT
	return roundi(cost)


func buy_upgrade(model: String, stat: String) -> bool:
	var cost := upgrade_cost(model, stat)
	if cost < 0 or dna < cost or not is_owned(model):
		return false
	dna -= cost
	if not workshop.has(model):
		workshop[model] = {}
	workshop[model][stat] = workshop_level(model, stat) + 1
	save()
	return true


# --- ящики и избранные модели ---------------------------------------------------------------

## Вскрыть ящик (обычный или военный). Пустой словарь — ящиков нет.
## Дубликат модели превращается в ДНК (обычная 40, редкая 100): kind остаётся "model", duplicate = true.
func open_crate(military: bool) -> Dictionary:
	if (crates if not military else military_crates) <= 0:
		return {}
	if military:
		military_crates -= 1
	else:
		crates -= 1
	var res := {"kind": "dna", "model": "", "dna": 0, "duplicate": false, "rare": false}
	if rng.randf() < (MILITARY_MODEL_CHANCE if military else CRATE_MODEL_CHANCE):
		var rare := rng.randf() < (MILITARY_RARE_CHANCE if military else CRATE_RARE_CHANCE)
		var pool := WeaponDefs.crate_models(WeaponDefs.Rarity.RARE if rare else WeaponDefs.Rarity.COMMON)
		var model: String = pool[rng.randi() % pool.size()]
		res["kind"] = "model"
		res["model"] = model
		res["rare"] = rare
		if is_owned(model):
			res["duplicate"] = true
			res["dna"] = DUPLICATE_DNA[rare]
		else:
			owned.append(model)
	else:
		res["dna"] = rng.randi_range(DNA_PACK_MIN, DNA_PACK_MAX)
	dna += int(res["dna"])
	save()
	return res


## Модель категории, которую предлагает Level Up: избранная или серийная.
func model_for(base: int) -> String:
	var model: String = favorite.get(base, "")
	if model != "" and is_owned(model) and WeaponDefs.MODELS[model]["base"] == base:
		return model
	return WeaponDefs.serial_model(base)


func set_favorite(base: int, model: String) -> bool:
	if not is_owned(model) or WeaponDefs.MODELS[model]["base"] != base:
		return false
	favorite[base] = model
	save()
	return true


# --- итоги забега -----------------------------------------------------------------------------

## stats — словарь экрана итогов: dna_total, crates, military_crates.
func add_run(stats: Dictionary) -> void:
	apply_run(stats)
	save()


## Часть транзакции без записи: кампании нужен один общий снимок наград и мира.
func apply_run(stats: Dictionary) -> void:
	if stats.get("endless", false):
		if stats.get("endless_credited", false):
			return
		var rewards := endless_rewards(float(stats.get("time", 0.0)))
		stats.merge(rewards, true)
		stats["endless_record"] = record_endless(str(stats.get("map_id", "")), str(stats.get("class_id", "")), float(stats.get("time", 0.0)), int(stats.get("kills", 0)))
		stats["endless_credited"] = true
	var gain := maxi(int(stats.get("dna_total", 0)), 0)
	last_run = {"dna": gain, "crates": maxi(int(stats.get("crates", 0)), 0), "military_crates": maxi(int(stats.get("military_crates", 0)), 0)}
	dna += gain
	dna_earned += gain
	crates += int(last_run["crates"])
	military_crates += int(last_run["military_crates"])
	runs += 1
	refresh_tree_gates()
	_refresh_first_tabs()


static func endless_rewards(seconds: float) -> Dictionary:
	var minutes := maxi(0, floori(seconds / 60.0)) if is_finite(seconds) else 0
	return {"dna_total": minutes * ENDLESS_DNA_PER_MINUTE, "crates": mini(minutes / ENDLESS_CRATE_MINUTES, ENDLESS_CRATE_CAP), "military_crates": 0, "dna_mult": 1.0,
		"dna_lines": [["Время в зоне (4 ДНК/мин)", minutes * ENDLESS_DNA_PER_MINUTE]]}


func endless_best(map: String, kind: String) -> Dictionary:
	return endless_records.get(map + ":" + kind, {"time": 0, "kills": 0}).duplicate()


## Время и убийства — независимые рекорды; трофеи следуют из лучшего времени.
func record_endless(map: String, kind: String, seconds: float, kills: int) -> Dictionary:
	if not map in ENDLESS_MAPS or not kind in ClassTree.CLASSES or not is_finite(seconds) or seconds < 0.0 or kills < 0:
		return {}
	var old := endless_best(map, kind)
	var survived := floori(seconds)
	var trophies: Array[int] = []
	for at: int in ENDLESS_MILESTONES:
		if int(old["time"]) < at and survived >= at:
			trophies.append(at / 60)
	endless_records[map + ":" + kind] = {"time": maxi(int(old["time"]), survived), "kills": maxi(int(old["kills"]), kills)}
	return {"time": survived > int(old["time"]), "kills": kills > int(old["kills"]), "previous_time": old["time"], "previous_kills": old["kills"], "trophies": trophies}


static func clean_endless(value: Variant) -> Dictionary:
	var cleaned := {}
	if not value is Dictionary:
		return cleaned
	for map: String in ENDLESS_MAPS:
		for kind: String in ClassTree.CLASSES:
			var key := map + ":" + kind
			var entry: Variant = value.get(key)
			if not entry is Dictionary:
				continue
			if not _is_num(entry.get("time")) or not _is_num(entry.get("kills")):
				continue
			if not is_finite(float(entry["time"])) or not is_finite(float(entry["kills"])) or float(entry["time"]) < 0.0 or float(entry["kills"]) < 0.0:
				continue
			cleaned[key] = {"time": int(minf(float(entry["time"]), 2147483647.0)), "kills": int(minf(float(entry["kills"]), 2147483647.0))}
	return cleaned


# --- сохранение -------------------------------------------------------------------------------

func reset() -> void:
	first_run = {"done": false, "started": false, "skipped": false, "hints": {}, "seen_tabs": {}, "open_tabs": {}}
	endless_records = {}
	campaign = CampaignRules.initial(int(CampaignCatalog.BALANCE["seed"]))
	campaign_recovered = false
	last_save_ok = true
	settings = clean_settings({})
	dna = 0
	dna_earned = 0
	tree = {}
	class_id = "assault"
	ClassTree.active = class_id
	class_trees = {"assault": {}, "gunner": {}, "engineer": {}}
	tree_gates = {}
	workshop = {}
	owned = PackedStringArray()
	favorite = {}
	crates = 0
	military_crates = 0
	runs = 0
	last_run = {}
	last_error = ""
	for id: String in WeaponDefs.MODEL_ORDER:
		if WeaponDefs.MODELS[id]["rarity"] == WeaponDefs.Rarity.SERIAL:
			owned.append(id)


func to_dict() -> Dictionary:
	refresh_tree_gates()
	_refresh_first_tabs()
	class_trees[class_id] = tree.duplicate()
	var fav := {}
	for b in favorite:
		fav[str(b)] = favorite[b]
	var result := {"version": SAVE_VERSION, "class_id": class_id, "class_trees": class_trees.duplicate(true), "dna": dna, "dna_earned": dna_earned, "tree": tree.duplicate(), "tree_gates": tree_gates.duplicate(), "workshop": workshop.duplicate(true),
		"owned": Array(owned), "favorite": fav, "crates": crates, "military_crates": military_crates, "runs": runs, "settings": settings.duplicate(), "campaign": campaign.duplicate(true)}
	# У старого профиля нет новых полей, кроме версии. Вводная фиксируется при реальном входе.
	if not first_run.get("skipped", false) and (first_run.get("started", false) or first_run.get("done", false) or not first_run["hints"].is_empty()):
		result["first_run"] = first_run.duplicate(true)
	# Необязательный блок v8: пустой профиль сохраняет прежние поля без добавок.
	if not endless_records.is_empty():
		result["endless_records"] = endless_records.duplicate(true)
	return result


func save() -> void:
	_settings_dirty = false
	save_calls += 1
	last_save_ok = true
	if not persist:
		return
	if not _write_atomic(save_path, JSON.stringify(to_dict(), "\t")):
		last_save_ok = false
		last_error = "запись %s не удалась" % save_path
		push_warning("Meta: " + last_error)


## Запись через временный файл: при сбое старое сохранение остаётся целым.
static func _write_atomic(path: String, text: String) -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text)
	f.flush()
	var write_ok := f.get_error() == OK
	f.close()
	return write_ok and DirAccess.rename_absolute(tmp, path) == OK


## Читает save_path. Нет файла — чистое состояние. Битый или чужой версии — резервная копия
## рядом и чистое сохранение. Возвращает true, если файл прочитан как есть.
func load_save() -> bool:
	reset()
	if not FileAccess.file_exists(save_path):
		return false
	var text := FileAccess.get_file_as_string(save_path)
	var json := JSON.new()
	if json.parse(text) == OK and json.data is Dictionary and from_dict(json.data):
		if campaign_recovered:
			var backup := "%s.campaign-bad-%d" % [save_path, Time.get_ticks_usec()]
			var copied := DirAccess.copy_absolute(save_path, backup) == OK
			last_error = "блок campaign повреждён; профиль сохранён; новая кампания; " + ("копия в " + backup if copied else "резервная копия не записана")
			print("Meta: " + last_error)
			if copied:
				save()
		elif int(json.data["version"]) < SAVE_VERSION:
			save() # v1/v2 → v3 без сброса профиля и без пометки повреждения
		return true
	var backup := "%s.bad-%d" % [save_path, int(Time.get_unix_time_from_system())]
	DirAccess.copy_absolute(save_path, backup)
	reset()
	last_error = "сохранение повреждено или другой версии, копия в " + backup
	print("Meta: " + last_error)
	save()
	return false


static func _is_num(v: Variant) -> bool:
	return v is float or v is int


## Разбор словаря сохранения со строгой проверкой типов. false — данные негодны целиком.
func from_dict(d: Dictionary) -> bool:
	if not _is_num(d.get("version")) or int(d["version"]) not in [1, 2, 3, 4, 5, 6, 7, 8, 9, SAVE_VERSION]:
		return false
	for key in ["dna", "dna_earned", "crates", "military_crates", "runs"]:
		if not _is_num(d.get(key)) or float(d[key]) < 0.0:
			return false
	if not (d.get("tree") is Dictionary and d.get("workshop") is Dictionary and d.get("owned") is Array and d.get("favorite") is Dictionary):
		return false
	var new_tree := {}
	# v1–v5: девять прежних id сохраняют те же эффекты и цену, переносим покупки один к одному.
	# Порядок каталога устраняет сирот и взаимоисключающие пары, даже в подправленном JSON.
	var budget := 0
	while budget < MAX_CLASS_LEVEL - 1 and int(d["dna_earned"]) >= dna_for_level(budget + 2):
		budget += 1
	var next_class := str(d.get("class_id", "assault")) if int(d["version"]) >= 7 else "assault"
	if not next_class in ClassTree.CLASSES: next_class = "assault"
	var saved_trees: Dictionary = d.get("class_trees", {}).duplicate(true) if d.get("class_trees") is Dictionary and int(d["version"]) >= 7 else {}
	saved_trees[next_class] = d["tree"]
	var clean_trees: Dictionary = {}
	for kind: String in ClassTree.CLASSES:
		var source: Dictionary = saved_trees.get(kind, {}) if saved_trees.get(kind) is Dictionary else {}
		var cleaned: Dictionary = {}
		var remaining := budget
		var catalog := ClassTree.catalog(kind)
		for pass_index in 72:
			var count := cleaned.size()
			for id: String in catalog:
				var n: Dictionary = catalog[id]
				if source.get(id) == true and not cleaned.has(id) and not cleaned.has(n["exclude"]) and remaining >= int(n["cost"]) and (int(d["version"]) < 7 or ClassTree.parents_met(n, cleaned)):
					cleaned[id] = true
					remaining -= int(n["cost"])
			if cleaned.size() == count: break
		clean_trees[kind] = cleaned
	new_tree = clean_trees[next_class]
	var new_workshop := {}
	for model in d["workshop"]:
		if not WeaponDefs.MODELS.has(model) or not d["workshop"][model] is Dictionary:
			continue
		var levels := {}
		for stat in d["workshop"][model]:
			if WORKSHOP_STATS.has(stat) and _is_num(d["workshop"][model][stat]):
				levels[stat] = clampi(int(d["workshop"][model][stat]), 0, WORKSHOP_MAX)
		new_workshop[model] = levels
	var new_owned := PackedStringArray()
	# Порядок уже открытых моделей — часть профиля; миграция его сохраняет.
	for id: Variant in d["owned"]:
		if id is String and WeaponDefs.MODELS.has(id) and not new_owned.has(id):
			new_owned.append(id)
	for id: String in WeaponDefs.MODEL_ORDER:
		if WeaponDefs.MODELS[id]["rarity"] == WeaponDefs.Rarity.SERIAL and not new_owned.has(id):
			new_owned.append(id)
	dna = int(d["dna"])
	dna_earned = int(d["dna_earned"])
	crates = int(d["crates"])
	military_crates = int(d["military_crates"])
	runs = int(d["runs"])
	# Старый профиль, даже без завершённых забегов, никогда не отправляем на обучение.
	first_run = {"done": true, "hints": {}, "seen_tabs": {}, "open_tabs": {}, "skipped": true}
	if int(d["version"]) >= 9 and d.get("first_run") is Dictionary:
		var source: Dictionary = d["first_run"]
		first_run = {"done": source.get("done") == true, "started": source.get("started") == true, "skipped": source.get("skipped") == true, "hints": {}, "seen_tabs": {}, "open_tabs": {}}
		for key: String in FIRST_HINTS:
			if source.get("hints") is Dictionary and source["hints"].get(key) == true:
				first_run["hints"][key] = true
		for key: String in ["0", "1", "2", "3", "4"]:
			if source.get("seen_tabs") is Dictionary and source["seen_tabs"].get(key) == true:
				first_run["seen_tabs"][key] = true
			if source.get("open_tabs") is Dictionary and source["open_tabs"].get(key) == true:
				first_run["open_tabs"][key] = true
	endless_records = clean_endless(d.get("endless_records", {}))
	tree = new_tree
	class_id = next_class
	ClassTree.active = class_id
	class_trees = clean_trees
	tree_gates = {}
	if d.get("tree_gates") is Dictionary:
		for gate: String in ["runs5", "runs10", "nest"]:
			if d["tree_gates"].get(gate) == true:
				tree_gates[gate] = true
	workshop = new_workshop
	owned = new_owned
	favorite = {}
	settings = clean_settings(d.get("settings", {}))
	for b in d["favorite"]:
		var model: String = str(d["favorite"][b])
		if str(b).is_valid_int() and WeaponDefs.MODELS.has(model) and owned.has(model) and WeaponDefs.MODELS[model]["base"] == int(b):
			favorite[int(b)] = model
	campaign_recovered = false
	if not d.has("campaign") and int(d["version"]) < SAVE_VERSION:
		campaign = CampaignRules.initial(int(CampaignCatalog.BALANCE["seed"]))
	elif CampaignRules.valid(CampaignRules.migrate(d.get("campaign"))):
		campaign = CampaignRules.normalized(CampaignRules.migrate(d["campaign"]))
	else:
		campaign = CampaignRules.initial(int(CampaignCatalog.BALANCE["seed"]))
		campaign_recovered = true
	refresh_tree_gates()
	return true


# --- флаги командной строки ----------------------------------------------------------------

func needs_first_run() -> bool:
	return not first_run.get("done", false)


func begin_first_run() -> void:
	first_run["started"] = true
	save()


func hint_done(id: String) -> bool:
	return first_run.get("skipped", false) or first_run.get("hints", {}).get(id, false)


func complete_hint(id: String) -> void:
	if not FIRST_HINTS.has(id) or hint_done(id):
		return
	first_run["hints"][id] = true
	save()


func finish_first_run(skipped := false) -> void:
	first_run["done"] = true
	first_run["skipped"] = skipped
	save()


func tab_open(id: int) -> bool:
	if first_run.get("skipped", false):
		return true
	if first_run.get("open_tabs", {}).get(str(id), false):
		return true
	if id in [2, 3]:
		return not needs_first_run()
	if id in [1, 4]:
		return runs >= 2
	return skill_points() > 0 or runs >= 3


func _refresh_first_tabs() -> void:
	for id in 5:
		if tab_open(id):
			first_run["open_tabs"][str(id)] = true


func tab_new(id: int) -> bool:
	return not first_run.get("skipped", false) and tab_open(id) and not first_run["seen_tabs"].has(str(id))


func visit_tab(id: int) -> void:
	if tab_new(id):
		first_run["seen_tabs"][str(id)] = true
		save()


func tab_requirement(id: int) -> String:
	return "2 вылазки" if id in [1, 4] else ("Очко навыка / 3 вылазки" if id == 0 else "Первая вылазка")


func _apply_cmdline(args: PackedStringArray) -> void:
	if args.has("--fresh-save"):
		if save_path == SAVE_PATH: persist = false
		reset()
	for a in args:
		if a.begins_with("--class="): select_class(a.trim_prefix("--class="))
	for a in args:
		if a == "--fresh-save":
			continue
		elif a.begins_with("--meta-preset="):
			apply_preset(a.trim_prefix("--meta-preset="))
		elif a.begins_with("--class="):
			continue
		elif a.begins_with("--meta="):
			apply_json(a.trim_prefix("--meta="))


## Готовые состояния для тестов: "maxed" — полный допустимый путь и мастерская.
func apply_preset(name: String) -> void:
	if name in ["tree-mid", "tree-full"]:
		tree.clear()
		dna_earned = dna_for_level(99)
		runs = 10
		tree_gates = {"runs5": true, "runs10": true, "nest": true}
		for pass_index in 72:
			for id: String in node_ids():
				if name == "tree-mid" and tree_spent() >= (42 if class_id == "assault" else 36): return
				if can_unlock(id): tree[id] = true
		return
	if name == "mid":
		dna_earned = dna_for_level(7)
		for id: String in ["fire_1", "fire_2", "mag_1", "mag_2", "surv_1", "surv_2"]:
			tree[id] = true
		for id: String in owned:
			workshop[id] = {"damage": 2, "rate": 2, "mag": 2, "reload": 2}
		return
	if name != "maxed":
		push_warning("Meta: неизвестный пресет «%s»" % name)
		return
	dna_earned = dna_for_level(99)
	dna = 5000
	apply_preset("tree-full")
	for id: String in WeaponDefs.MODEL_ORDER:
		if not owned.has(id):
			owned.append(id)
		workshop[id] = {"damage": WORKSHOP_MAX, "rate": WORKSHOP_MAX, "mag": WORKSHOP_MAX, "reload": WORKSHOP_MAX}


## Подмешивает в состояние поля из JSON (для --meta=): любые ключи формата сохранения.
func apply_json(text: String) -> void:
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_warning("Meta: --meta= не разобран как JSON-объект")
		return
	var d: Dictionary = parsed
	if d.has("settings"):
		settings = clean_settings(d["settings"])
	for key in ["dna", "dna_earned", "crates", "military_crates", "runs"]:
		if d.has(key):
			set(key, int(d[key]))
	if d.get("tree") is Dictionary:
		for id in d["tree"]:
			if node_ids().has(id):
				tree[id] = true
	if d.get("owned") is Array:
		for id in d["owned"]:
			if WeaponDefs.MODELS.has(id) and not owned.has(id):
				owned.append(id)
	if d.get("workshop") is Dictionary:
		for model in d["workshop"]:
			if WeaponDefs.MODELS.has(model) and d["workshop"][model] is Dictionary:
				if not workshop.has(model):
					workshop[model] = {}
				for stat in d["workshop"][model]:
					if WORKSHOP_STATS.has(stat):
						workshop[model][stat] = clampi(int(d["workshop"][model][stat]), 0, WORKSHOP_MAX)
	if d.get("favorite") is Dictionary:
		for b in d["favorite"]:
			var model: String = str(d["favorite"][b])
			if str(b).is_valid_int() and WeaponDefs.MODELS.has(model):
				if not owned.has(model):
					owned.append(model)
				favorite[int(b)] = model
