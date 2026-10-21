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
var focus_overflow := false
var _link_screens := 0
var _link_offered := false
var _link_pair := ""


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

func make_cards(minutes: float, level_screen := true) -> Array:
	var choosing_level := level - pending + 1 # уровень, за который сейчас выбираем
	var pool: Array = [] # [вес, карта]
	var slots := weapons.slots
	if slots.size() < WeaponDefs.MAX_SLOTS:
		var missing: Array = []
		for b in WeaponDefs.BASES:
			if not weapons.has_base(b):
				missing.append(b)
		var normalized := 0.0
		for b in missing: normalized += _partner_weight(b)
		for b in missing:
			pool.append([WEIGHTS["weapon"] * _partner_weight(b) / normalized, {"type": "weapon", "id": b}])
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
	var link := can_offer_link()
	for m in mods:
		pool.append([WEIGHTS["module"] * (0.8 if link else 1.0) / mods.size(), {"type": "module", "id": m}])
	if link:
		pool.append([WEIGHTS["module"] * 0.2, {"type": "link", "id": WeaponDefs.Module.LINK}])
	var ammo: Array[int] = []
	for a in WeaponDefs.AMMO.size():
		for i in slots.size():
			if ammo_status(i, a) != "":
				ammo.append(a)
				break
	for a in ammo:
		pool.append([WEIGHTS["ammo"] / ammo.size(), {"type": "ammo", "id": a}])
	var pas: Array = []
	for p in WeaponDefs.PASSIVES:
		if passives.get(p, 0) < WeaponDefs.MAX_PASSIVE:
			pas.append(p)
	for p in pas:
		pool.append([WEIGHTS["passive"] / pas.size(), {"type": "passive", "id": p}])

	var cards: Array = []
	var pair := link_pair_key()
	if pair != _link_pair:
		_link_pair = pair
		_link_screens = 0
		_link_offered = false
	if link and focus_overflow and level_screen: _link_screens += 1
	var weapon_guarantee := choosing_level in [2, 4] and slots.size() < 3
	if link and focus_overflow and not _link_offered and _link_screens >= 4 and not weapon_guarantee and level_screen:
		cards.append({"type": "link", "id": WeaponDefs.Module.LINK})
		for entry: Array in pool.duplicate():
			if entry[1]["type"] == "link": pool.erase(entry)
	# гарантия нового ствола на уровнях 2 и 4, пока стволов меньше трёх
	if weapon_guarantee and level_screen:
		var weapons_pool: Array = []
		for entry: Array in pool:
			if entry[1]["type"] == "weapon":
				weapons_pool.append(entry)
		var total := 0.0
		for entry: Array in weapons_pool:
			total += entry[0]
		var roll := randf() * total
		for entry: Array in weapons_pool:
			roll -= entry[0]
			if roll <= 0.0:
				cards.append(entry[1].duplicate())
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
	# Когда билд исчерпан, награда всё равно применяется.
	while cards.size() < 3:
		cards.append({"type": "credits", "amount": 20 + cards.size() * 5})
	var rare_chance := 0.05 + 0.015 * minutes
	for c: Dictionary in cards:
		c["rare"] = (c["type"] == "module" or c["type"] == "ammo") and randf() < rare_chance
		if c["type"] == "link" and level_screen: _link_offered = true
	return cards


func _partner_weight(base: int) -> float:
	if not focus_overflow: return 1.0
	var heavy := false
	var pellets := false
	for s in weapons.slots:
		heavy = heavy or Weapons.overflow_donor(s)
		pellets = pellets or Weapons.overflow_receiver(s)
	if heavy and not pellets and base in [WeaponDefs.Base.SHOTGUN, WeaponDefs.Base.AUTO_SHOTGUN]:
		var model: String = Meta.model_for(base)
		return 1.5 if WeaponDefs.MODELS[model]["trait"] != "slug" else 1.0
	if pellets and not heavy and base in [WeaponDefs.Base.RAIL, WeaponDefs.Base.SNIPER, WeaponDefs.Base.CROSSBOW, WeaponDefs.Base.REVOLVER]: return 1.5
	return 1.0


func can_offer_link() -> bool:
	for i in weapons.slots.size():
		if weapons.link_available(i): return true
	return false


func link_pair_key() -> String:
	var ids: Array[int] = []
	for s in weapons.slots:
		if Weapons.overflow_receiver(s) or Weapons.overflow_donor(s): ids.append(s.uid)
	return str(ids)


## Нужно ли выбирать ствол для карты (модуль, патроны).
static func needs_slot(card: Dictionary) -> bool:
	return card["type"] in ["module", "ammo", "link"]


## Что будет со стволом i, если поставить модуль m; пустая строка — нельзя.
func module_status(i: int, m: int) -> String:
	if m == WeaponDefs.Module.LINK: return ""
	var s: Weapons.Slot = weapons.slots[i]
	if s.base == WeaponDefs.Base.LAUNCHER and (m == WeaponDefs.Module.RICOCHET or (m == WeaponDefs.Module.CHAIN and s.mod_rank(WeaponDefs.Module.DETONATOR) == 0)): return ""
	if not WeaponDefs.supports_module(s.base, m): return ""
	var have := s.module(m)
	if not have.is_empty():
		var r: int = have["rank"]
		return "" if r >= WeaponDefs.MAX_RANK else "%s → %s" % [WeaponDefs.ROMAN[r], WeaponDefs.ROMAN[r + 1]]
	var free := WeaponDefs.module_slots(s.level) - s.modules.size()
	if free > 0: return "новый слот"
	return "заменит Перелив" if not s.module(WeaponDefs.Module.LINK).is_empty() else ""


func ammo_status(i: int, a: int) -> String:
	var s: Weapons.Slot = weapons.slots[i]
	if not WeaponDefs.supports_ammo(s.base, a): return ""
	if s.ammo == a:
		return "" if s.ammo_rank >= WeaponDefs.MAX_RANK else "%s → %s" % [WeaponDefs.ROMAN[s.ammo_rank], WeaponDefs.ROMAN[s.ammo_rank + 1]]
	return "заменит «%s»" % WeaponDefs.AMMO[s.ammo]["name"]


func slot_status(card: Dictionary, i: int) -> String:
	if card["type"] == "link":
		if link_replacing(card):
			var s := weapons.slots[weapons.slot_by_uid(int(card["receiver_uid"]))]
			return "заменить" if i >= 0 and i < s.modules.size() and int(s.modules[i]["id"]) != WeaponDefs.Module.LINK else ""
		var moving := link_instance(int(card.get("rebind", 0)))
		if card.has("rebind") and moving.is_empty(): return ""
		if card.has("receiver_uid"):
			var receiver := weapons.slot_by_uid(int(card["receiver_uid"]))
			return "партнёр" if weapons.link_available(receiver, i, moving) else ""
		return "получатель" if weapons.link_available(i, -1, moving) else ""
	if i < 0 or i >= weapons.slots.size(): return ""
	return module_status(i, card["id"]) if card["type"] == "module" else ammo_status(i, card["id"])


func link_replacing(card: Dictionary) -> bool:
	if card.get("type", "") != "link" or not card.has("receiver_uid") or card.has("replacement"): return false
	var receiver := weapons.slot_by_uid(int(card["receiver_uid"]))
	if receiver < 0: return false
	var s := weapons.slots[receiver]
	return s.modules.size() >= WeaponDefs.module_slots(s.level) and not s.modules.has(link_instance(int(card.get("rebind", 0))))


func link_instance(id: int) -> Dictionary:
	for s in weapons.slots:
		var m := s.module(WeaponDefs.Module.LINK)
		if not m.is_empty() and int(m["instance_id"]) == id: return m
	return {}


## Бот делает тот же явный выбор пары и заменяемой детали, что игрок в предпросмотре.
func auto_link(card: Dictionary, receiver: int) -> void:
	if card["type"] != "link" or card.has("receiver_uid") or receiver < 0: return
	for partner in weapons.slots.size():
		if not weapons.link_available(receiver, partner): continue
		card["partner_uid"] = weapons.slots[partner].uid
		var s := weapons.slots[receiver]
		if s.modules.size() >= WeaponDefs.module_slots(s.level):
			card["replacement"] = s.modules[0].duplicate(true)
		return


## Подсказка: поставить эту деталь на ствол i — шаг к прототипу?
func prototype_hint(card: Dictionary, i: int) -> String:
	if card["type"] == "link": return ""
	var s: Weapons.Slot = weapons.slots[i]
	for r: Dictionary in WeaponDefs.PROTOTYPES:
		if s.base != r["base"]:
			continue
		var fits: bool = (card["type"] == "module" and card["id"] == r["module"]) or (card["type"] == "ammo" and card["id"] == r["ammo"])
		if fits:
			return "Рецепт «%s»" % r["name"]
	return ""


# --- применение ----------------------------------------------------------------------------

## from_level_up = false — покупка у торговца (не списывает отложенный Level Up).
func apply(card: Dictionary, slot := -1, from_level_up := true) -> void:
	if card["type"] in ["module", "ammo"] and (slot < 0 or slot >= weapons.slots.size() or slot_status(card, slot) == ""):
		return
	if card["type"] == "link":
		var partner := weapons.slot_by_uid(int(card.get("partner_uid", 0)))
		if card.has("rebind"):
			var moving := link_instance(int(card["rebind"]))
			if moving.is_empty() or moving["active"]: return
			weapons.rebind_link(moving, slot, partner, card.get("replacement", {}))
			return
		if not weapons.install_link(slot, partner, card.get("replacement", {})): return
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
				if s.modules.size() >= WeaponDefs.module_slots(s.level):
					s.modules.erase(s.module(WeaponDefs.Module.LINK))
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
		"credits":
			credits += int(card["amount"])
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


var _preview_cache := {}


## Прогноз проходит тот же refresh, что покупка, на отдельном стволе без сцены и сигналов игры.
func comparison(card: Dictionary, target := -1) -> Dictionary:
	if card["type"] == "link":
		if target < 0 or target >= weapons.slots.size(): return {}
		return {"cap": weapons.overflow_limit(weapons.slots[target]), "seconds": Weapons.LINK_TIME,
			"share": Weapons.OVERFLOW_SHARE, "replacement": card.get("replacement", {})}
	if card["type"] == "level":
		target = int(card["slot"])
	if card["type"] not in ["weapon", "level", "module", "ammo"]:
		return {}
	if needs_slot(card) and (target < 0 or slot_status(card, target) == ""):
		return {}
	var source: Weapons.Slot = weapons.slots[target] if target >= 0 else null
	var key := var_to_str([card, target, source.stats if source else {}, source.modules if source else [],
		source.level if source else 0, source.ammo if source else 0, source.ammo_rank if source else 0,
		source.ammo_rare if source else false, weapons.passives, weapons.bonuses, Meta.workshop])
	if _preview_cache.has(key):
		return _preview_cache[key]
	var ghost := Weapons.new()
	ghost.bonuses = weapons.bonuses
	ghost.passives = weapons.passives
	var s := Weapons.Slot.new()
	s.set_model(source.model if source else str(card.get("model", Meta.model_for(card["id"]))))
	s.visual_model = s.model
	if source:
		s.level = source.level
		s.modules = source.modules.duplicate(true)
		s.ammo = source.ammo
		s.ammo_rank = source.ammo_rank
		s.ammo_rare = source.ammo_rare
	ghost.slots.append(s)
	ghost.refresh(0)
	var before := s.stats.duplicate(true)
	var before_dps := sustained_dps(s)
	var rank_before := 0
	var old_icon := ""
	var lost_charge := -1.0
	match card["type"]:
		"level":
			s.level += 1
		"module":
			var have := s.module(card["id"])
			rank_before = int(have.get("rank", 0))
			if have.is_empty():
				if s.modules.size() >= WeaponDefs.module_slots(s.level):
					var lost := s.module(WeaponDefs.Module.LINK)
					lost_charge = float(source.module(WeaponDefs.Module.LINK).get("charge", 0.0))
					s.modules.erase(lost)
				s.modules.append({"id": card["id"], "rank": 1, "rare": card["rare"]})
			else:
				have["rank"] += 1
				have["rare"] = have["rare"] or card["rare"]
		"ammo":
			rank_before = s.ammo_rank if s.ammo == card["id"] else 0
			if s.ammo != card["id"]:
				old_icon = "card_ammo_%d" % s.ammo
			s.ammo_rank = rank_before + 1
			s.ammo_rare = card["rare"] or (s.ammo_rare and s.ammo == card["id"])
			s.ammo = card["id"]
	ghost.refresh(0)
	var after := s.stats.duplicate(true)
	var rows: Array = []
	if card["type"] == "weapon":
		rows = [["dps", "", _num(sustained_dps(s))], ["range", "", _num(after["range"])]]
	elif card["type"] == "level":
		rows.append(["dps", _num(before_dps), _num(sustained_dps(s))])
		for pair: Array in [["damage", "damage"], ["proj", "fan"], ["mag", "mag"], ["reload", "reload"], ["radius", "blast"], ["width", "line"], ["range", "range"], ["crit", "crit"], ["rate", "rate"], ["knock", "push"], ["pierce", "line"]]:
			if before.has(pair[0]) and not is_equal_approx(float(before[pair[0]]), float(after[pair[0]])):
				rows.append([pair[1], _num(before[pair[0]]), _num(after[pair[0]])])
	else:
		rows.append(["rank", str(rank_before), str(rank_before + 1)])
		if not is_equal_approx(before_dps, sustained_dps(s)):
			rows.append(["dps", _num(before_dps), _num(sustained_dps(s))])
		for pair: Array in [["radius", "blast"], ["width", "line"], ["proj", "fan"]]:
			if before.has(pair[0]) and not is_equal_approx(float(before[pair[0]]), float(after[pair[0]])):
				rows.append([pair[1], _num(before[pair[0]]), _num(after[pair[0]])])
	var result := {"before": before, "after": after, "rows": rows, "old_icon": old_icon, "model": s.model, "lost_charge": lost_charge}
	ghost.free()
	if _preview_cache.size() > 64:
		_preview_cache.clear()
	_preview_cache[key] = result
	return result


## Ожидаемый урон по одной цели без промахов, с магазином, перезарядкой и чертой модели.
static func sustained_dps(s: Weapons.Slot) -> float:
	var st := s.stats
	var shots_time: float = float(st["mag"]) / float(st["rate"])
	if s.base in [WeaponDefs.Base.LMG, WeaponDefs.Base.MINIGUN]:
		shots_time += (0.35 if s.base == WeaponDefs.Base.LMG else 0.9) * (0.5 if s.trait_id == "quick_spin" else 1.0)
	if s.trait_id == "fan":
		shots_time = WeaponDefs.FAN_TIME * WeaponDefs.FAN_BASE_RATE / float(st["rate"])
	var chance: float = float(st["crit"]) + 0.05
	var multiplier := 2.0
	if s.ammo == WeaponDefs.Ammo.STANDARD:
		chance += [0.10, 0.15, 0.15][s.ammo_rank - 1] * (WeaponDefs.RARE_MULT if s.ammo_rare else 1.0)
		if s.ammo_rank >= 3:
			multiplier = 2.5
	var crit := 1.0 + clampf(chance, 0.0, 1.0) * (multiplier - 1.0)
	if s.trait_id == "last_round":
		crit *= 1.0 + 2.0 / float(st["mag"])
	return float(st["damage"]) * int(st["proj"]) * float(st["mag"]) / (shots_time + float(st["reload"])) * crit


static func pattern(base: int) -> String:
	if base in [WeaponDefs.Base.SHOTGUN, WeaponDefs.Base.AUTO_SHOTGUN, WeaponDefs.Base.REVOLVER, WeaponDefs.Base.FLAMER]:
		return "fan"
	if base in [WeaponDefs.Base.LAUNCHER, WeaponDefs.Base.TESLA]:
		return "blast"
	return "line"


static func role(base: int) -> String:
	if base in [WeaponDefs.Base.RAIL, WeaponDefs.Base.SNIPER, WeaponDefs.Base.DMR, WeaponDefs.Base.CROSSBOW]:
		return "precision"
	if base in [WeaponDefs.Base.LAUNCHER, WeaponDefs.Base.TESLA]:
		return "blast"
	if base in [WeaponDefs.Base.SHOTGUN, WeaponDefs.Base.AUTO_SHOTGUN, WeaponDefs.Base.SAW, WeaponDefs.Base.FLAMER]:
		return "role"
	return "crowd"


# --- тексты карт ----------------------------------------------------------------------------

## Карта для отрисовки (U3, меньше текста): kind — метка вида, title — название, color, icon (имя спрайта в art/,
## icon_gun — спрайт ствола, он крупнее иконок деталей), big и unit — ОДНА крупная цифра эффекта и её подпись
## («+20%» / «урон»), round — [вид патрона, магазин] для ряда настоящих патронов на карте ствола,
## details — строки по наведению или выбору стрелками: описание, черта, ранги I–III.
func describe(card: Dictionary) -> Dictionary:
	var rare: bool = card.get("rare", false)
	match card["type"]:
		"link":
			return {"kind": "СВЯЗЬ", "title": "Перелив", "color": C_COMMON, "icon": "sy2_overflow", "big": "1", "unit": "заряд",
				"details": ["%d%% избытка одного тяжёлого убийства → следующий дробовой залп." % roundi(Weapons.OVERFLOW_SHARE * 100), "Один заряд на 6 с. Одно место модуля; без рангов."]}
		"credits":
			return {"kind": "СНАБЖЕНИЕ", "title": "Кредиты", "color": C_WEAPON, "icon": "", "big": "+%d" % int(card["amount"]), "unit": "кредиты", "details": []}
		"weapon":
			# предлагается избранная модель категории (Meta.model_for): её имя, описание и черта
			var model: String = card.get("model", Meta.model_for(card["id"]))
			var m: Dictionary = WeaponDefs.MODELS[model]
			var st := WeaponDefs.model_stats(model, 1)
			var details: Array = [m.get("desc", WeaponDefs.BASES[card["id"]]["desc"])]
			if m["trait"] != "":
				details.append("Черта «%s»: %s" % [WeaponDefs.TRAITS[m["trait"]]["name"], WeaponDefs.TRAITS[m["trait"]]["text"]])
			details.append("%.1f выстр/с · перезарядка %s с" % [st["rate"], _num(st["reload"])])
			var model_rare: bool = m["rarity"] == WeaponDefs.Rarity.RARE
			var proj := int(st["proj"])
			return {"kind": "НОВЫЙ СТВОЛ" + (" · РЕДКИЙ" if model_rare else ""), "title": m["name"], "color": C_RARE if model_rare else C_WEAPON,
				"icon": "gun_" + model, "icon_gun": true, "big": _num(st["damage"]), "unit": "урон" + (" ×%d" % proj if proj > 1 else ""),
				"round": [HudRounds.kind_of(m["base"]), int(st["mag"])], "details": details}
		"level":
			var s: Weapons.Slot = weapons.slots[card["slot"]]
			var up: Dictionary = WeaponDefs.level_info(s.model, s.level + 1)
			var details: Array = [up["text"]]
			if WeaponDefs.module_slots(s.level + 1) > WeaponDefs.module_slots(s.level):
				details.append("+1 слот модуля")
			if s.level + 1 == WeaponDefs.MAX_LEVEL:
				details.append("ур. 5 открывает прототипы")
			var big := WeaponDefs.level_big(up)
			return {"kind": "УЛУЧШЕНИЕ СТВОЛА", "title": "%s → ур. %d" % [s.short_name(), s.level + 1], "color": C_COMMON,
				"icon": "gun_" + s.model, "icon_gun": true, "big": big[0], "unit": big[1], "details": details}
		"module":
			var d: Dictionary = WeaponDefs.MODULES[card["id"]]
			return {"kind": "МОДУЛЬ" + (" · РЕДКИЙ" if rare else ""), "title": d["name"], "color": C_RARE if rare else C_COMMON,
				"icon": "card_mod_%d" % card["id"], "big": d["big"][0], "unit": d["big"][1], "details": _with_ranks(d["desc"], d["ranks"])}
		"ammo":
			var d: Dictionary = WeaponDefs.AMMO[card["id"]]
			return {"kind": "ПАТРОНЫ" + (" · РЕДКИЕ" if rare else ""), "title": d["name"], "color": C_RARE if rare else C_COMMON,
				"icon": "card_ammo_%d" % card["id"], "big": d["big"][0], "unit": d["big"][1], "details": _with_ranks(d["desc"], d["ranks"])}
		"passive":
			var d: Dictionary = WeaponDefs.PASSIVES[card["id"]]
			var lv: int = passives.get(card["id"], 0)
			return {"kind": "ПАССИВКА", "title": "%s %s" % [d["name"], WeaponDefs.ROMAN[lv + 1]], "color": C_PASSIVE,
				"icon": "card_pas_%d" % card["id"], "big": d["big"][0], "unit": d["big"][1], "details": ["уровень %d из %d" % [lv + 1, WeaponDefs.MAX_PASSIVE]]}
	return {"kind": "", "title": "?", "color": C_COMMON, "icon": "", "big": "", "unit": "", "details": []}


static var _icon_cache: Dictionary = {}


## Спрайт карты из общего кэша. Все иконки подгружаются заранее (preload_icons): первый кадр не рисует белое пятно.
static func card_icon(icon_name: String) -> Texture2D:
	if not _icon_cache.has(icon_name):
		_icon_cache[icon_name] = PixelArt.tex(icon_name)
	return _icon_cache[icon_name]


static func preload_icons() -> void:
	card_icon("sy2_overflow")
	for id: String in WeaponDefs.MODEL_ORDER:
		card_icon("gun_" + id)
	for k in 6:
		card_icon("card_mod_%d" % k)
		card_icon("card_pas_%d" % k)
	for k in 4:
		card_icon("card_ammo_%d" % k)


## Описание и ранги I–III по строке: всё это по наведению, на лицевой стороне карты — только крупная цифра.
static func _with_ranks(desc: String, ranks: Array) -> Array:
	var out: Array = [desc]
	for k in ranks.size():
		out.append("%s: %s" % [WeaponDefs.ROMAN[k + 1], ranks[k]])
	return out
