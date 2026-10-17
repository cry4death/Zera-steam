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
##   --meta-preset=maxed   всё дерево, мастерская 5/5, все модели, много ДНК
##   --save-file=<путь>    писать и читать этот файл (user://имя.json) даже в тест-режиме: проверка перезапуска

const SAVE_VERSION := 1
const SAVE_PATH := "user://zera_save.json"
## Любой из этих флагов (по началу строки) — тест-режим игры: сохранение только в памяти.
const TEST_FLAGS := ["--sim", "--bench", "--boss", "--alarm", "--ui-test", "--weapons-test", "--loadout", "--s3-test", "--meta-test", "--kinds", "--gore-stress", "--fresh-save"]

# Уровень класса: накоплено ДНК для уровня n = 80 · (n − 1)^1.5 (BALANCE §11.2)
const LEVEL_DNA_K := 80.0
const MAX_CLASS_LEVEL := 99

## Дерево Штурмовика (GDD §12.1): ветка → три узла по порядку.
const TREE := [
	{"id": "fire", "name": "Огневая мощь", "nodes": [
		{"id": "fire_1", "name": "Пристрелка", "text": "+8% урона"},
		{"id": "fire_2", "name": "Бронебой", "text": "+10% шанс крита"},
		{"id": "fire_3", "name": "Шквал огня", "text": "после 3 с непрерывной стрельбы +20% скорострельности"}]},
	{"id": "mag", "name": "Магазин", "nodes": [
		{"id": "mag_1", "name": "Быстрые руки", "text": "перезарядка −15%"},
		{"id": "mag_2", "name": "Расширенные магазины", "text": "+20% ёмкости"},
		{"id": "mag_3", "name": "Последний патрон", "text": "последний патрон магазина бьёт ×3 и всегда рвёт на гибы"}]},
	{"id": "surv", "name": "Выживание", "nodes": [
		{"id": "surv_1", "name": "Бронежилет", "text": "+20 HP"},
		{"id": "surv_2", "name": "Рефлексы", "text": "+1 заряд рывка"},
		{"id": "surv_3", "name": "Адреналин", "text": "рывок мгновенно перезаряжает все стволы (КД 10 с)"}]},
]
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
var workshop := {} # model_id → {"damage": 0..5, "rate": .., "mag": .., "reload": ..}
var owned := PackedStringArray() # открытые модели (серийные — всегда)
var favorite := {} # Base → model_id
var crates := 0
var military_crates := 0
var runs := 0

var persist := true # false — состояние только в памяти (тест-режимы)
var save_path := SAVE_PATH
var rng := RandomNumberGenerator.new()
var last_error := "" # причина последнего сбоя загрузки/записи (для тестов и отладки)
var last_run := {} # что дал последний add_run: {"dna", "crates", "military_crates"}


func _ready() -> void:
	rng.randomize()
	reset()
	var args := OS.get_cmdline_user_args()
	# База тестируется только в памяти, даже если одновременно передан --save-file.
	if args.has("--base-test"):
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


## Запущен ли любой тест-режим игры (флаги из TEST_FLAGS). S6 использует то же для маршрутизации сцен.
static func is_test_run(args: PackedStringArray = OS.get_cmdline_user_args()) -> bool:
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
	return maxi(class_level() - 1 - tree.size(), 0)


## Все узлы в порядке «ветка по ветке».
static func node_ids() -> Array[String]:
	var out: Array[String] = []
	for branch: Dictionary in TREE:
		for node: Dictionary in branch["nodes"]:
			out.append(node["id"])
	return out


## Можно ли открыть узел: он существует, закрыт, предыдущий в ветке открыт, есть очко навыка.
func can_unlock(node: String) -> bool:
	if tree.has(node) or skill_points() <= 0:
		return false
	for branch: Dictionary in TREE:
		var nodes: Array = branch["nodes"]
		for i in nodes.size():
			if nodes[i]["id"] == node:
				return i == 0 or tree.has(nodes[i - 1]["id"])
	return false


func unlock(node: String) -> bool:
	if not can_unlock(node):
		return false
	tree[node] = true
	save()
	return true


## Бонусы забега из дерева. Закрытый узел даёт нейтральное значение.
## dash_charges — всего зарядов рывка (1 или 2), sustained_rate — доля прироста темпа после 3 с стрельбы.
func run_bonuses() -> Dictionary:
	return {
		"damage_mul": 1.08 if tree.has("fire_1") else 1.0,
		"crit_add": 0.10 if tree.has("fire_2") else 0.0,
		"sustained_rate": 0.20 if tree.has("fire_3") else 0.0,
		"reload_mul": 0.85 if tree.has("mag_1") else 1.0,
		"mag_mul": 1.20 if tree.has("mag_2") else 1.0,
		"last_round": tree.has("mag_3"),
		"hp_add": 20.0 if tree.has("surv_1") else 0.0,
		"dash_charges": 2 if tree.has("surv_2") else 1,
		"adrenaline": tree.has("surv_3"),
	}


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
	var gain := maxi(int(stats.get("dna_total", 0)), 0)
	last_run = {"dna": gain, "crates": maxi(int(stats.get("crates", 0)), 0), "military_crates": maxi(int(stats.get("military_crates", 0)), 0)}
	dna += gain
	dna_earned += gain
	crates += int(last_run["crates"])
	military_crates += int(last_run["military_crates"])
	runs += 1
	save()


# --- сохранение -------------------------------------------------------------------------------

func reset() -> void:
	dna = 0
	dna_earned = 0
	tree = {}
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
	var fav := {}
	for b in favorite:
		fav[str(b)] = favorite[b]
	return {"version": SAVE_VERSION, "dna": dna, "dna_earned": dna_earned, "tree": tree.duplicate(), "workshop": workshop.duplicate(true),
		"owned": Array(owned), "favorite": fav, "crates": crates, "military_crates": military_crates, "runs": runs}


func save() -> void:
	if not persist:
		return
	if not _write_atomic(save_path, JSON.stringify(to_dict(), "\t")):
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
	f.close()
	return DirAccess.rename_absolute(tmp, path) == OK


## Читает save_path. Нет файла — чистое состояние. Битый или чужой версии — резервная копия
## рядом и чистое сохранение. Возвращает true, если файл прочитан как есть.
func load_save() -> bool:
	reset()
	if not FileAccess.file_exists(save_path):
		return false
	var text := FileAccess.get_file_as_string(save_path)
	var json := JSON.new()
	if json.parse(text) == OK and json.data is Dictionary and from_dict(json.data):
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
	if not _is_num(d.get("version")) or int(d["version"]) != SAVE_VERSION:
		return false
	for key in ["dna", "dna_earned", "crates", "military_crates", "runs"]:
		if not _is_num(d.get(key)) or float(d[key]) < 0.0:
			return false
	if not (d.get("tree") is Dictionary and d.get("workshop") is Dictionary and d.get("owned") is Array and d.get("favorite") is Dictionary):
		return false
	var new_tree := {}
	var ids := node_ids()
	for id in d["tree"]:
		if id is String and ids.has(id) and d["tree"][id]:
			new_tree[id] = true
	# открытые узлы должны идти по порядку внутри ветки
	for branch: Dictionary in TREE:
		var gap := false
		for node: Dictionary in branch["nodes"]:
			if not new_tree.has(node["id"]):
				gap = true
			elif gap:
				new_tree.erase(node["id"])
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
	for id: String in WeaponDefs.MODEL_ORDER:
		if WeaponDefs.MODELS[id]["rarity"] == WeaponDefs.Rarity.SERIAL or d["owned"].has(id):
			new_owned.append(id)
	dna = int(d["dna"])
	dna_earned = int(d["dna_earned"])
	crates = int(d["crates"])
	military_crates = int(d["military_crates"])
	runs = int(d["runs"])
	tree = new_tree
	workshop = new_workshop
	owned = new_owned
	favorite = {}
	for b in d["favorite"]:
		var model: String = str(d["favorite"][b])
		if str(b).is_valid_int() and WeaponDefs.MODELS.has(model) and owned.has(model) and WeaponDefs.MODELS[model]["base"] == int(b):
			favorite[int(b)] = model
	return true


# --- флаги командной строки ----------------------------------------------------------------

func _apply_cmdline(args: PackedStringArray) -> void:
	for a in args:
		if a == "--fresh-save":
			if save_path == SAVE_PATH:
				persist = false # без своего файла чистое состояние живёт только в памяти
			reset()
		elif a.begins_with("--meta-preset="):
			apply_preset(a.trim_prefix("--meta-preset="))
		elif a.begins_with("--meta="):
			apply_json(a.trim_prefix("--meta="))


## Готовые состояния для тестов: "maxed" — всё открыто и прокачано.
func apply_preset(name: String) -> void:
	if name != "maxed":
		push_warning("Meta: неизвестный пресет «%s»" % name)
		return
	dna_earned = dna_for_level(10)
	dna = 5000
	for id in node_ids():
		tree[id] = true
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
