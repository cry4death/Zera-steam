class_name Progression
extends Node
## Опыт, уровни и карты Level Up (BALANCE.md §8): веса, гарантии, редкость, применение.

signal level_ready # накопились уровни — пора показывать выбор

const WEIGHTS := {"weapon": 20.0, "level": 30.0, "module": 25.0, "ammo": 10.0, "passive": 15.0}
const C_COMMON := Color(0.92, 0.9, 0.85)
const C_RARE := Color(0.45, 0.72, 1.0)
const C_WEAPON := Color(1.0, 0.8, 0.35)
const C_PASSIVE := Color(0.55, 0.95, 0.6)

var weapons: Weapons
var player: Player
var gems: Gems

var xp := 0
var level := 1
var pending := 0
var rerolls := 1
var credits := 0 # кредиты забега: падают с врагов, тратятся у торговца
var passives := {}


static func xp_to_next(l: int) -> int:
	return roundi(6.0 * pow(l, 1.3))


func add_xp(v: int) -> void:
	xp += v
	while xp >= xp_to_next(level):
		xp -= xp_to_next(level)
		level += 1
		pending += 1
	if pending > 0:
		level_ready.emit()


# --- генерация карт ---------------------------------------------------------------------

func make_cards(minutes: float) -> Array:
	var choosing_level := level - pending + 1 # уровень, за который сейчас выбираем
	var pool: Array = [] # [вес, карта]
	var slots := weapons.slots
	if slots.size() < WeaponDefs.MAX_SLOTS:
		var missing: Array = []
		for b in WeaponDefs.BASES:
			if not weapons.has_base(b):
				missing.append(b)
		for b in missing:
			pool.append([WEIGHTS["weapon"] / missing.size(), {"type": "weapon", "id": b}])
	var upgradable: Array = []
	for i in slots.size():
		if slots[i].level < WeaponDefs.MAX_LEVEL:
			upgradable.append(i)
	for i in upgradable:
		pool.append([WEIGHTS["level"] / upgradable.size(), {"type": "level", "slot": i}])
	var mods: Array = []
	for m in WeaponDefs.MODULES:
		for i in slots.size():
			if module_status(i, m) != "":
				mods.append(m)
				break
	for m in mods:
		pool.append([WEIGHTS["module"] / mods.size(), {"type": "module", "id": m}])
	for a in WeaponDefs.AMMO.size():
		pool.append([WEIGHTS["ammo"] / WeaponDefs.AMMO.size(), {"type": "ammo", "id": a}])
	var pas: Array = []
	for p in WeaponDefs.PASSIVES:
		if passives.get(p, 0) < WeaponDefs.MAX_PASSIVE:
			pas.append(p)
	for p in pas:
		pool.append([WEIGHTS["passive"] / pas.size(), {"type": "passive", "id": p}])

	var cards: Array = []
	# гарантия нового ствола на уровнях 2 и 4, пока стволов меньше трёх
	if choosing_level in [2, 4] and slots.size() < 3:
		for entry: Array in pool:
			if entry[1]["type"] == "weapon":
				cards.append(entry[1])
				pool.erase(entry)
				break
	while cards.size() < 3 and not pool.is_empty():
		var total := 0.0
		for entry: Array in pool:
			total += entry[0]
		var r := randf() * total
		for entry: Array in pool:
			r -= entry[0]
			if r <= 0.0:
				cards.append(entry[1])
				pool.erase(entry)
				break
	var rare_chance := 0.05 + 0.015 * minutes
	for c: Dictionary in cards:
		c["rare"] = (c["type"] == "module" or c["type"] == "ammo") and randf() < rare_chance
	return cards


## Нужно ли выбирать ствол для карты (модуль, патроны).
static func needs_slot(card: Dictionary) -> bool:
	return card["type"] == "module" or card["type"] == "ammo"


## Что будет со стволом i, если поставить модуль m; пустая строка — нельзя.
func module_status(i: int, m: int) -> String:
	var s: Weapons.Slot = weapons.slots[i]
	var have := s.module(m)
	if not have.is_empty():
		var r: int = have["rank"]
		return "" if r >= WeaponDefs.MAX_RANK else "%s → %s" % [WeaponDefs.ROMAN[r], WeaponDefs.ROMAN[r + 1]]
	var free := WeaponDefs.module_slots(s.level) - s.modules.size()
	return "новый слот" if free > 0 else ""


func ammo_status(i: int, a: int) -> String:
	var s: Weapons.Slot = weapons.slots[i]
	if s.ammo == a:
		return "" if s.ammo_rank >= WeaponDefs.MAX_RANK else "%s → %s" % [WeaponDefs.ROMAN[s.ammo_rank], WeaponDefs.ROMAN[s.ammo_rank + 1]]
	return "заменит «%s»" % WeaponDefs.AMMO[s.ammo]["name"]


func slot_status(card: Dictionary, i: int) -> String:
	return module_status(i, card["id"]) if card["type"] == "module" else ammo_status(i, card["id"])


## Подсказка: поставить эту деталь на ствол i — шаг к прототипу?
func prototype_hint(card: Dictionary, i: int) -> String:
	var s: Weapons.Slot = weapons.slots[i]
	for r: Dictionary in WeaponDefs.PROTOTYPES:
		if s.base != r["base"]:
			continue
		var fits: bool = (card["type"] == "module" and card["id"] == r["module"]) or (card["type"] == "ammo" and card["id"] == r["ammo"])
		if fits:
			return "◆ рецепт «%s»" % r["name"]
	return ""


# --- применение ----------------------------------------------------------------------------

## from_level_up = false — покупка у торговца (не списывает отложенный Level Up).
func apply(card: Dictionary, slot := -1, from_level_up := true) -> void:
	match card["type"]:
		"weapon":
			weapons.add_weapon(card["id"])
		"level":
			var s: Weapons.Slot = weapons.slots[card["slot"]]
			s.level += 1
			weapons.refresh(card["slot"])
		"module":
			var s: Weapons.Slot = weapons.slots[slot]
			var have := s.module(card["id"])
			if have.is_empty():
				s.modules.append({"id": card["id"], "rank": 1, "rare": card["rare"]})
			else:
				have["rank"] = mini(have["rank"] + 1, WeaponDefs.MAX_RANK)
				have["rare"] = have["rare"] or card["rare"] # при стакинге берётся старшая редкость
			weapons.refresh(slot)
		"ammo":
			var s: Weapons.Slot = weapons.slots[slot]
			if s.ammo == card["id"]:
				s.ammo_rank = mini(s.ammo_rank + 1, WeaponDefs.MAX_RANK)
				s.ammo_rare = s.ammo_rare or card["rare"]
			else:
				s.ammo = card["id"]
				s.ammo_rank = 1
				s.ammo_rare = card["rare"]
			weapons.refresh(slot)
		"passive":
			var p: int = card["id"]
			passives[p] = passives.get(p, 0) + 1
			_apply_passives(p)
	if from_level_up:
		pending = maxi(pending - 1, 0)


func _apply_passives(changed: int) -> void:
	weapons.passives = passives
	weapons.refresh_all()
	var lv: int = passives.get(changed, 0)
	match changed:
		WeaponDefs.Passive.HP:
			player.max_hp += WeaponDefs.PASSIVES[changed]["per_level"]
			player.hp = minf(player.hp + WeaponDefs.PASSIVES[changed]["per_level"], player.max_hp)
		WeaponDefs.Passive.SPEED:
			player.move_speed = 80.0 * (1.0 + WeaponDefs.PASSIVES[changed]["per_level"] * lv)
		WeaponDefs.Passive.PICKUP:
			gems.radius = 32.0 * (1.0 + WeaponDefs.PASSIVES[changed]["per_level"] * lv)


## Число без хвоста «.0»: 7 → «7», 3.5 → «3.5».
static func _num(v: float) -> String:
	return "%d" % roundi(v) if is_equal_approx(v, roundf(v)) else "%.1f" % v


# --- тексты карт ----------------------------------------------------------------------------

## {kind, title, lines, color} для отрисовки карты. Для компактной лицевой стороны (U1-14) дополнительно:
## icon — имя спрайта в art/ (icon_gun — спрайт ствола, он крупнее иконок деталей), sub — короткое описание,
## front — эффект получаемого ранга, more — подробности (ранги II–III, черта), показываются по наведению.
func describe(card: Dictionary) -> Dictionary:
	var rare: bool = card.get("rare", false)
	match card["type"]:
		"weapon":
			# предлагается избранная модель категории (Meta.model_for): её имя, описание и черта
			var model: String = card.get("model", Meta.model_for(card["id"]))
			var m: Dictionary = WeaponDefs.MODELS[model]
			var st := WeaponDefs.model_stats(model, 1)
			var stats := "урон %s · %.1f выстр/с · магазин %d" % [_num(st["damage"]), st["rate"], st["mag"]]
			var lines: Array = [m.get("desc", WeaponDefs.BASES[card["id"]]["desc"])]
			var more: Array = []
			if m["trait"] != "":
				var trait_line := "Черта «%s»: %s" % [WeaponDefs.TRAITS[m["trait"]]["name"], WeaponDefs.TRAITS[m["trait"]]["text"]]
				lines.append(trait_line)
				more.append(trait_line)
			lines.append(stats)
			var model_rare: bool = m["rarity"] == WeaponDefs.Rarity.RARE
			return {"kind": "НОВЫЙ СТВОЛ" + (" · РЕДКИЙ" if model_rare else ""), "title": m["name"], "color": C_RARE if model_rare else C_WEAPON,
				"lines": lines, "icon": "gun_" + model, "icon_gun": true, "sub": lines[0], "front": [stats], "more": more}
		"level":
			var s: Weapons.Slot = weapons.slots[card["slot"]]
			var up: Dictionary = WeaponDefs.level_info(s.model, s.level + 1)
			var lines: Array = [up["text"]]
			if WeaponDefs.module_slots(s.level + 1) > WeaponDefs.module_slots(s.level):
				lines.append("+1 слот модуля")
			if s.level + 1 == WeaponDefs.MAX_LEVEL:
				lines.append("ур. 5 открывает прототипы")
			return {"kind": "УЛУЧШЕНИЕ СТВОЛА", "title": "%s → ур. %d" % [s.short_name(), s.level + 1], "color": C_COMMON, "lines": lines,
				"icon": "gun_" + s.model, "icon_gun": true, "sub": "", "front": lines, "more": []}
		"module":
			var d: Dictionary = WeaponDefs.MODULES[card["id"]]
			return {"kind": "МОДУЛЬ" + (" · РЕДКИЙ" if rare else ""), "title": d["name"], "color": C_RARE if rare else C_COMMON,
				"lines": [d["desc"]], "ranks": d["ranks"], "icon": "card_mod_%d" % card["id"], "sub": d["desc"],
				"front": ["%s: %s" % [WeaponDefs.ROMAN[1], d["ranks"][0]]], "more": _more_ranks(d["ranks"])}
		"ammo":
			var d: Dictionary = WeaponDefs.AMMO[card["id"]]
			return {"kind": "ПАТРОНЫ" + (" · РЕДКИЕ" if rare else ""), "title": d["name"], "color": C_RARE if rare else C_COMMON,
				"lines": [d["desc"]], "ranks": d["ranks"], "icon": "card_ammo_%d" % card["id"], "sub": d["desc"],
				"front": ["%s: %s" % [WeaponDefs.ROMAN[1], d["ranks"][0]]], "more": _more_ranks(d["ranks"])}
		"passive":
			var d: Dictionary = WeaponDefs.PASSIVES[card["id"]]
			var lv: int = passives.get(card["id"], 0)
			var lines: Array = [d["text"], "уровень %d из %d" % [lv + 1, WeaponDefs.MAX_PASSIVE]]
			return {"kind": "ПАССИВКА", "title": "%s %s" % [d["name"], WeaponDefs.ROMAN[lv + 1]], "color": C_PASSIVE,
				"lines": lines, "icon": "card_pas_%d" % card["id"], "sub": "", "front": lines, "more": []}
	return {"kind": "", "title": "?", "color": C_COMMON, "lines": [], "icon": "", "sub": "", "front": [], "more": []}


static var _icon_cache: Dictionary = {}


## Спрайт карты из общего кэша. Все иконки подгружаются заранее (preload_icons): первый кадр не рисует белое пятно.
static func card_icon(icon_name: String) -> Texture2D:
	if not _icon_cache.has(icon_name):
		_icon_cache[icon_name] = PixelArt.tex(icon_name)
	return _icon_cache[icon_name]


static func preload_icons() -> void:
	for id: String in WeaponDefs.MODEL_ORDER:
		card_icon("gun_" + id)
	for k in 6:
		card_icon("card_mod_%d" % k)
		card_icon("card_pas_%d" % k)
	for k in 4:
		card_icon("card_ammo_%d" % k)


## Ранги II–III одной строкой каждый (ранг I вынесен на лицевую сторону).
static func _more_ranks(ranks: Array) -> Array:
	var out: Array = []
	for k in range(1, mini(3, ranks.size())):
		out.append("%s: %s" % [WeaponDefs.ROMAN[k + 1], ranks[k]])
	return out
